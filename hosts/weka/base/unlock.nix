# Unlocking the encrypted root pool (rpool/crypt) at boot: clevis gets the
# passphrase from a Tang server, and if that fails, SSH in the initrd asks for
# it. See "Reboots and unlocking" in README.md.
{ config, lib, pkgs, ... }:
let
  # clevis, but leaving /run/clevis-unlocked behind when a decrypt succeeds.
  # The import prints nothing either way, and /run carries over from the
  # initrd, so stage 2 can tell an unattended unlock from a passphrase one
  # (boot_unlocked_by_clevis in monitoring/prometheus.nix).
  clevisMarked = pkgs.writeShellScript "clevis" ''
    if [ "$1" = decrypt ]; then
      ${config.boot.initrd.clevis.package}/bin/clevis "$@" && : > /run/clevis-unlocked
    else
      exec ${config.boot.initrd.clevis.package}/bin/clevis "$@"
    fi
  '';
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
      # If that fails, the import falls through to the passphrase prompt above.
      # The .jwe holds the passphrase sealed to the Tang key, so like the SSH
      # host key it stays out of the store and this repo (string path, copied
      # in by boot.initrd.secrets). Made by hand, see "Reboots and unlocking".
      # @see: https://github.com/jay-aye-see-kay/nixfiles/issues/4
      clevis = {
        enable = true;
        useTang = true;
        devices."rpool/crypt".secretFile = "/etc/secrets/initrd/rpool-crypt.jwe";
      };
      # The clevis module adds curl but no CA bundle, so HTTPS would fail
      systemd.contents."/etc/ssl/certs/ca-certificates.crt".source = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      # clevis-decrypt-tang makes one curl call and the import runs it once,
      # so retry here. Long enough for the router and internet to come back
      # after a power cut, short enough that the passphrase fallback (which
      # waits for this) isn't a chore. Worst case 10 attempts x 6s + 9 x 3s =
      # 87s (max-time also cuts clevis's own 10s connect timeout).
      # IPv4 only, since the Tang key set allows only the home IPv4.
      systemd.contents."/etc/curl/.curlrc".text = ''
        retry = 9
        retry-delay = 3
        retry-all-errors
        max-time = 6
        retry-max-time = 90
        ipv4
        cacert = /etc/ssl/certs/ca-certificates.crt
      '';
      systemd.services.zfs-import-rpool.environment.CURL_HOME = "/etc/curl";
      systemd.extraBin.clevis = lib.mkForce clevisMarked;
      systemd.storePaths = [ clevisMarked ];
    };
  };

  # Weekly upgrades from GitHub reboot by themselves when the kernel or initrd
  # changed (03:00-05:00, see modules/nixos/common.nix): the root pool unlocks
  # from Tang, see boot.initrd.clevis above.

  # TEMPORARY (#4): reboot daily for a few weeks, to prove auto-unlock holds
  # up. 04:30 is after restic (02:00), syncoid (03:30) and the Sunday upgrade
  # (03:00 + up to 30 min); it skips the night if any of them is still going.
  # boot_unlocked_by_clevis (monitoring/prometheus.nix) records how each boot
  # unlocked. Delete this when #4 is closed.
  systemd.services.unlock-test-reboot = {
    description = "Daily reboot to test auto-unlock (temporary)";
    serviceConfig.Type = "oneshot";
    script = ''
      for unit in nixos-upgrade restic-backups-weka syncoid-rpool-crypt-data; do
        if systemctl is-active --quiet "$unit.service"; then
          echo "$unit is still running, not rebooting tonight"
          exit 0
        fi
      done
      systemctl reboot
    '';
    startAt = "*-*-* 04:30:00";
  };
}
