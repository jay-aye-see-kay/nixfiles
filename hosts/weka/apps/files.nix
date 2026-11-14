# Shared files over SMB: smb://weka.tarpan-krait.ts.net/shared from anywhere
# on the tailnet (direct on the home LAN, so the same address works at home
# and away). Also allowed from the LAN by IP. Data is its own ZFS dataset,
# rpool/crypt/data/files, so sanoid and restic pick it up.
#
# No NetBIOS (nmbd), wsdd or Avahi: they only advertise on the local network
# and don't cross Tailscale. Add the server once in Finder (Go → Connect to
# Server) instead.
#
# Samba keeps its own password database (/var/lib/samba/private/passdb.tdb),
# separate from the Unix accounts. samba-passwords sets it from sops on every
# boot and whenever a password changes, so nothing is set by hand.
# @see: https://wiki.samba.org/index.php/Configure_Samba_to_Work_Better_with_Mac_OS_X
{ config, lib, pkgs, ... }:
let
  smbUsers = [ "jack" "nora" ];
  smbpasswd = lib.getExe' config.services.samba.package "smbpasswd";
in
{
  users.groups.family = { };
  users.users.jack.extraGroups = [ "family" ];
  # Only for Samba: no password, no SSH keys, no shell, so no way to log in
  # to weka itself.
  users.users.nora = {
    isNormalUser = true;
    extraGroups = [ "family" ];
    createHome = false;
    home = "/var/empty";
    shell = "${pkgs.shadow}/bin/nologin";
  };

  sops.secrets = lib.genAttrs (map (u: "samba_password_${u}") smbUsers) (_: {
    restartUnits = [ "samba-passwords.service" ];
  });

  systemd.services.samba-passwords = {
    description = "Set Samba passwords from sops";
    wantedBy = [ "multi-user.target" ];
    before = [ "samba-smbd.service" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = lib.concatMapStrings
      (u: ''
        pw=$(cat ${config.sops.secrets."samba_password_${u}".path})
        printf '%s\n%s\n' "$pw" "$pw" | ${smbpasswd} -s -a ${u} >/dev/null
      '')
      smbUsers;
  };

  # setgid, so everything created in the share stays group family
  systemd.tmpfiles.settings."10-files"."/srv/files/shared".d = {
    user = "root";
    group = "family";
    mode = "2770";
  };

  services.samba = {
    enable = true;
    nmbd.enable = false;
    winbindd.enable = false;
    settings = {
      global = {
        "server string" = "weka";
        "server min protocol" = "SMB3";
        security = "user";
        "map to guest" = "never";
        # tailnet (100.64.0.0/10) and the home LAN; the firewall below only
        # opens 445 on those two interfaces anyway
        "hosts allow" = "100.64.0.0/255.192.0.0 192.168.10. 127.0.0.1";
        "hosts deny" = "0.0.0.0/0";
        # no printers
        "load printers" = "no";
        printing = "bsd";
        "printcap name" = "/dev/null";
        "disable spoolss" = "yes";
        # macOS: Finder metadata and resource forks as xattrs, Mac-friendly
        # filenames
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:model" = "MacSamba";
        "fruit:posix_rename" = "yes";
        "fruit:veto_appledouble" = "no";
        "fruit:nfs_aces" = "no";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles" = "yes";
      };
      shared = {
        path = "/srv/files/shared";
        "valid users" = "@family";
        "read only" = "no";
        "force group" = "family";
        "create mask" = "0660";
        "directory mask" = "2770";
      };
    };
  };

  networking.firewall.interfaces = {
    lan0.allowedTCPPorts = [ 445 ];
    tailscale0.allowedTCPPorts = [ 445 ];
  };

  weka.datasets."data/files" = "/srv/files";
}
