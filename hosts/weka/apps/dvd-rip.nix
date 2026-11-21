# Headless DVD ripping from a USB drive. Insert a disc and it's copied off
# (decrypted with libdvdcss), ejected, then encoded with HandBrake in the
# background, one title per file. Nothing names the episodes: TV discs only
# say something like FRIENDS_S1_D2, so move the results from
# /srv/media/rips/encoded into /srv/media/tv/<Show>/Season NN/ by hand
# (Jellyfin wants "Show S01E05.mkv"), then delete the folder.
#
# Two stages so the drive is free in a few minutes rather than tied up for
# the hour an encode takes, and you can feed it the next disc:
#   dvd-rip@sr0  udev starts it when a DVD goes in. dvdbackup mirrors the
#                disc to rips/incoming/<label>, then ejects.
#   dvd-encode   started after each rip (OnSuccess), works through incoming/ one disc at a
#                time, at low CPU priority so Jellyfin's transcodes still win.
#
# Discs dvdbackup chokes on (bad sectors, structure protection) want MakeMKV
# instead: unfree, and needs its beta key in ~/.MakeMKV/settings.conf.
#
# Once, on weka (not tmpfiles, see arr/default.nix):
#   sudo install -d -g media -m 2775 /srv/media/rips
#
# Follow along with: journalctl -fu 'dvd-rip@*' -u dvd-encode
# @see: https://handbrake.fr/docs/en/latest/cli/command-line-reference.html
{ lib, pkgs, ... }:
let
  rips = "/srv/media/rips";
  incoming = "${rips}/incoming";
  encoded = "${rips}/encoded";

  # Titles outside this range are skipped. Under: menus, trailers, recaps.
  # Over: the "play all" title that's every episode back to back. Raise the
  # max for discs of feature-length episodes or films.
  minSeconds = 15 * 60;
  maxSeconds = 75 * 60;

  # Australian discs are PAL. Matroska keeps every audio and (bitmap)
  # subtitle track without converting them.
  preset = "H.265 MKV 576p25";

  # Builds with the GTK GUI by default, which is only closure size on a
  # headless box. `.override { useGtk = false; }` drops it, at the cost of
  # building HandBrake from source (no binary cache for that variant).
  handbrake = pkgs.handbrake;

  common = {
    after = [ "local-fs.target" ];
    unitConfig.RequiresMountsFor = [ "/srv/media" ];
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      # cdrom for /dev/sr*, media to write next to the library
      SupplementaryGroups = [ "cdrom" "media" ];
      UMask = "0002";
      ProtectSystem = "strict";
      ReadWritePaths = [ rips ];
      ProtectHome = true;
      PrivateTmp = true;
      PrivateNetwork = true;
      NoNewPrivileges = true;
    };
  };
in
{
  # The drive appears as sr0 (sr1 for a second one). "change" is the disc
  # going in, not the drive being plugged in. RUN rather than SYSTEMD_WANTS,
  # which systemd only acts on for "add".
  services.udev.extraRules = ''
    ACTION=="change", SUBSYSTEM=="block", KERNEL=="sr[0-9]*", ENV{ID_CDROM_MEDIA_DVD}=="1", RUN+="${pkgs.systemd}/bin/systemctl --no-block start dvd-rip@%k.service"
  '';

  systemd.services."dvd-rip@" = lib.recursiveUpdate common {
    description = "Copy the DVD in /dev/%i to ${incoming}";
    path = [ pkgs.dvdbackup pkgs.util-linux pkgs.coreutils ];
    unitConfig.OnSuccess = [ "dvd-encode.service" ];
    serviceConfig = {
      # Just optical drives. PrivateDevices would hide them.
      DevicePolicy = "closed";
      DeviceAllow = [ "block-sr rw" ];
    };
    scriptArgs = "%i";
    script = ''
      set -euo pipefail
      dev=/dev/$1
      mkdir -p ${incoming} ${encoded}

      label=$(blkid -o value -s LABEL "$dev" || true)
      label=''${label:-disc}
      # Two discs with the same label (it happens) don't overwrite each other
      [ -e "${incoming}/$label" ] || [ -e "${encoded}/$label" ] && label="$label-$(date +%Y%m%d-%H%M%S)"

      # Into a .part folder, so a failed copy is never picked up for encoding
      dvdbackup -i "$dev" -o ${incoming} -n "$label.part" -M
      mv "${incoming}/$label.part" "${incoming}/$label"
      eject "$dev" || true
    '';
  };

  systemd.services.dvd-encode = lib.recursiveUpdate common {
    description = "Encode the DVDs in ${incoming} with HandBrake";
    path = [ handbrake pkgs.jq pkgs.gnused pkgs.coreutils pkgs.findutils ];
    serviceConfig = {
      Nice = 15;
      CPUWeight = 20;
      IOSchedulingClass = "idle";
      PrivateDevices = true;
      # A season of SD DVDs is a few hours per disc in software x265
      TimeoutStartSec = "infinity";
    };
    script = ''
      set -euo pipefail
      shopt -s nullglob

      # A disc ripped while this is running doesn't start a second run (the
      # start merges into this one), so look again until incoming/ is done.
      # A disc with no usable titles is skipped and stays put.
      declare -A seen
      while :; do
        found=
        for src in ${incoming}/*/; do
          src=''${src%/}
          name=$(basename "$src")
          [[ $name == *.part ]] && continue
          [ -n "''${seen[$name]:-}" ] && continue
          seen[$name]=1 found=1
          out="${encoded}/$name"
          mkdir -p "$out"
          echo "Encoding $name"

          # Index of every title within the length range
          titles=$(HandBrakeCLI -i "$src" -t 0 --scan --json 2>/dev/null \
            | sed -n '/^JSON Title Set:/,/^}/p' | sed '1s/^JSON Title Set: //' \
            | jq -r '.TitleList[]
                | select(.Duration.Hours*3600 + .Duration.Minutes*60 + .Duration.Seconds
                         | . >= ${toString minSeconds} and . <= ${toString maxSeconds})
                | .Index')

          if [ -z "$titles" ]; then
            echo "No titles between ${toString minSeconds}s and ${toString maxSeconds}s in $name, leaving it in ${incoming}" >&2
            continue
          fi

          for t in $titles; do
            dest=$(printf '%s/title_%02d.mkv' "$out" "$t")
            [ -e "$dest" ] && continue
            HandBrakeCLI -i "$src" -t "$t" -o "$dest.part" \
              --preset "${preset}" \
              --all-audio --all-subtitles \
              --markers
            mv "$dest.part" "$dest"
          done

          rm -rf "$src"
        done
        [ -n "$found" ] || break
      done
    '';
  };
}
