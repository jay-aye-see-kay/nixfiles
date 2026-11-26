# Unlocking the encrypted root pool (rpool/crypt) at boot: clevis keeps trying
# to get the passphrase from a Tang server, and meanwhile SSH in the initrd can
# be used to type it in. See "Reboots and unlocking" in README.md.
{ config, pkgs, ... }:
let
  dataset = "rpool/crypt";
  jwe = "/etc/clevis/rpool-crypt.jwe";
in
{
  boot = {
    zfs.requestEncryptionCredentials = true;

    # Remote unlock: SSH in the initrd on port 2222, LAN only (or via the
    # UniFi WireGuard VPN from away). Logging in drops straight into the
    # passphrase prompt. See "Reboots and unlocking" in README.md.
    # @see: https://elis.nu/blog/2026/04/nixos-zfs-remote-unlock-over-ssh/
    initrd = {
      systemd.enable = true;
      # Onboard Realtek RTL8111, renamed to lan0. Its network is shared with
      # stage 2, see network.nix.
      availableKernelModules = [ "r8169" ];
      systemd.network.enable = true;
      network.ssh = {
        enable = true;
        port = 2222;
        # Separate from the main host key, so it's fine that it sits
        # unencrypted in the initrd on the ESP. Kept in 1Password and copied
        # in with nixos-anywhere --extra-files at install (see README.md).
        hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
        # The same keys that can log in as root once it's up
        authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
      };
      systemd.users.root.shell = "/bin/systemd-tty-ask-password-agent";

      # Auto-unlock: clevis gets the passphrase back from a Tang server (keystone,
      # a Cloudflare Worker deployed from the infra repo, gated to the home IP).
      # The .jwe holds the passphrase sealed to the Tang key, so like the SSH
      # host key it stays out of the store and this repo (string path, copied
      # in by boot.initrd.secrets). Made by hand, see "Reboots and unlocking".
      #
      # Not through clevis.devices: with that, the pool import tries Tang once
      # and only then shows the passphrase prompt, so a short Tang timeout gives
      # up before a slow internet comes back (the 2026-11-26 power cut: WAN back
      # 12 minutes after weka booted), and a long one holds up SSH unlock.
      # Instead the prompt comes up straight away, and tang-unlock below keeps
      # trying Tang and answers it, like clevis-luks-askpass does for LUKS.
      # Whichever answers first, this or SSH, unlocks the pool.
      # @see: https://github.com/jay-aye-see-kay/nixfiles/issues/4
      clevis = {
        # Only for the clevis, jose and curl binaries in the initrd
        enable = true;
        # Off so the pool import doesn't wait for network-online before
        # prompting. tang-unlock waits for the network by retrying.
        useTang = false;
      };
      secrets.${jwe} = "/etc/secrets/initrd/rpool-crypt.jwe";
      # The clevis module adds curl but no CA bundle, so HTTPS would fail
      systemd.contents."/etc/ssl/certs/ca-certificates.crt".source = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      # One short try per attempt, tang-unlock does the retrying. IPv4 only,
      # since the Tang key set allows only the home IPv4.
      systemd.contents."/etc/curl/.curlrc".text = ''
        max-time = 6
        ipv4
        cacert = /etc/ssl/certs/ca-certificates.crt
      '';
      systemd.extraBin.systemd-reply-password = "${config.boot.initrd.systemd.package}/lib/systemd/systemd-reply-password";

      # Answers the import's passphrase prompt (systemd-ask-password, which
      # leaves a request in /run/systemd/ask-password) from Tang, retrying
      # until it works or the key is loaded some other way. Leaves
      # /run/clevis-unlocked behind when it answers: /run carries over from
      # the initrd, so stage 2 can tell an unattended unlock from a passphrase
      # one (boot_unlocked_by_clevis in monitoring/prometheus.nix). Its log
      # carries over too: journalctl -b -u tang-unlock.
      # @see: https://systemd.io/PASSWORD_AGENTS/
      systemd.services.tang-unlock = {
        description = "Answer the ${dataset} passphrase prompt from Tang";
        wantedBy = [ "initrd.target" ];
        before = [ "initrd-switch-root.target" ];
        conflicts = [ "initrd-switch-root.target" ];
        environment.CURL_HOME = "/etc/curl";
        script = ''
          message="Enter key for ${dataset}:"

          keyLoaded() {
            [ "$(zfs get -H -o value keystatus ${dataset} 2>/dev/null)" = available ]
          }

          # The reply socket of the pending prompt for ${dataset}, if there is one
          promptSocket() {
            local ask key value socket msg
            for ask in /run/systemd/ask-password/ask.*; do
              [ -e "$ask" ] || continue
              socket="" msg=""
              while IFS="=" read -r key value; do
                case "$key" in
                  Socket) socket=$value ;;
                  Message) msg=$value ;;
                esac
              done < "$ask"
              if [ "$msg" = "$message" ] && [ -n "$socket" ]; then
                echo "$socket"
                return 0
              fi
            done
            return 1
          }

          while ! keyLoaded; do
            if socket=$(promptSocket) && pass=$(clevis decrypt < ${jwe}) && [ -n "$pass" ]; then
              # A wrong answer would use up one of the prompt's three tries,
              # so check it first, and give up rather than keep answering
              if ! printf '%s' "$pass" | zfs load-key -n ${dataset}; then
                keyLoaded && exit 0
                echo "The passphrase from Tang doesn't unlock ${dataset}, leaving it to the prompt" >&2
                exit 1
              fi
              if printf '%s\n' "$pass" | systemd-reply-password 1 "$socket"; then
                : > /run/clevis-unlocked
                echo "Answered the ${dataset} prompt from Tang"
                exit 0
              fi
            fi
            sleep 10
          done
          echo "${dataset} was unlocked by hand"
        '';
      };
    };
  };

  # Weekly upgrades from GitHub reboot by themselves when the kernel or initrd
  # changed (03:00-05:00, see modules/nixos/common.nix): the root pool unlocks
  # from Tang, see tang-unlock above.
}
