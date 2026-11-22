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
#                A disc HandBrake fails on goes to rips/failed/ and the queue
#                carries on. Leftovers after a reboot wait for the next rip, or
#                `sudo systemctl start dvd-encode`.
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
  failed = "${rips}/failed";

  # Titles outside this range are skipped. Under: menus, trailers, recaps.
  # Over: the "play all" title that's every episode back to back. Raise the
  # max for discs of feature-length episodes or films.
  minSeconds = 15 * 60;
  maxSeconds = 75 * 60;

  # Australian discs are PAL, hence 576p25. x264 medium rather than x265: at
  # SD the size difference is small (~1-1.5 GB/hour vs ~0.6-1), x265 takes
  # several times the CPU, and every Jellyfin client plays H.264 without a
  # transcode. The built-in H.265 MKV presets are 10-bit x265 slow, the worst
  # of both. Matroska keeps the bitmap subtitles as they are.
  preset = "H.264 MKV 576p25";

  # Builds with the GTK GUI by default, which is only closure size on a
  # headless box. `.override { useGtk = false; }` drops it, at the cost of
  # building HandBrake from source (no binary cache for that variant).
  handbrake = pkgs.handbrake;

  common = {
    after = [ "local-fs.target" ];
    unitConfig.RequiresMountsFor = [ "/srv/media" ];
    serviceConfig = {
      Type = "oneshot";
      # A real user rather than DynamicUser: the files outlive the units and
      # end up in the library, where a recycled dynamic UID would own them.
      User = "dvd-rip";
      Group = "media";
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
  # cdrom for /dev/sr*, media to write next to the library
  users.users.dvd-rip = {
    isSystemUser = true;
    group = "media";
    extraGroups = [ "cdrom" ];
  };
  # To move the encodes into the library and clear out rips/ without sudo
  users.users.jack.extraGroups = [ "media" ];

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
      # Two of the four cores, so the box stays cool and quiet while a queue
      # of discs works through. x264 still encodes SD faster than real time.
      CPUQuota = "200%";
      # Oneshot, so no start timeout by default: a disc takes an hour or two
    };
    script = ''
      set -euo pipefail
      shopt -s nullglob

      # A disc ripped while this is running doesn't start a second run (the
      # start merges into this one), so look again until incoming/ is done.
      # A disc with no usable titles is skipped and stays put.
      mkdir -p ${failed}

      # Out of the queue, so one bad disc doesn't block the ones after it
      fail() {
        echo "$2, moving $name to ${failed}" >&2
        local dest="${failed}/$name"
        [ -e "$dest" ] && dest="$dest-$(date +%Y%m%d-%H%M%S)"
        mv -T "$1" "$dest"
      }

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
            fail "$src" "No titles between ${toString minSeconds}s and ${toString maxSeconds}s"
            continue
          fi

          for t in $titles; do
            dest=$(printf '%s/title_%02d.mkv' "$out" "$t")
            [ -e "$dest" ] && continue
            # Audio copied as-is (AC3, DTS and MP2 are all small at DVD
            # bitrates), keeping 5.1. The preset would make every track
            # stereo AAC. LPCM can't be copied, so falls back to that.
            if ! HandBrakeCLI -i "$src" -t "$t" -o "$dest.part" \
              --preset "${preset}" \
              --all-audio --aencoder copy \
              --audio-copy-mask ac3,dts,mp2,aac --audio-fallback aac \
              --all-subtitles \
              --markers; then
              rm -f "$dest.part"
              fail "$src" "HandBrake failed on title $t"
              continue 2
            fi
            mv "$dest.part" "$dest"
          done

          rm -rf "$src"
        done
        [ -n "$found" ] || break
      done
    '';
  };
}
