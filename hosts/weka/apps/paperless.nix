# Paperless-ngx at https://paperless.tarpan-krait.ts.net (a Tailscale Service,
# see platform/tailscale-services.nix). SQLite. Data, index and media are one ZFS
# dataset, rpool/crypt/data/paperless (see base/disko.nix).
#
# Scanning: the Brother MFC can't scan to SMB, only FTP or email, so vsftpd
# takes uploads from it straight into the consume folder. The only FTP login is
# `scanner`, it's chrooted to consume, and port 21 is open on the LAN only
# (FTP sends the password in plain text, which is accepted for a LAN-only
# account that can do nothing but drop files for Paperless). The scanner's FTP
# profile: host 192.168.10.101, port 21, passive mode, user scanner, folder /.
# @see: https://docs.paperless-ngx.com/configuration/
{ config, lib, ... }:
let
  port = 28981;
  cfg = config.services.paperless;
  passive = { from = 50000; to = 50009; };
in
{
  sops.secrets.paperless_admin_password = {
    restartUnits = [ "paperless-scheduler.service" ];
  };
  # Hashed (mkpasswd -m yescrypt); the plain one only lives in 1Password and
  # the scanner. Needed before users are created, so it's decrypted early.
  sops.secrets.scanner_password_hash.neededForUsers = true;

  services.paperless = {
    enable = true;
    address = "127.0.0.1";
    inherit port;
    # Creates/updates this superuser on start, with the password from sops
    passwordFile = config.sops.secrets.paperless_admin_password.path;
    settings = {
      PAPERLESS_ADMIN_USER = "jack";
      PAPERLESS_URL = "https://paperless.tarpan-krait.ts.net";
      # No PAPERLESS_OCR_LANGUAGE: English is the default, and setting it
      # makes the module rebuild tesseract and paperless with just those
      # languages, which is never in the binary cache (a long build with
      # paperless's whole test suite).
      PAPERLESS_CONSUMER_IGNORE_PATTERN = [
        ".DS_Store/*"
        "._*"
        "desktop.ini"
        "*.tmp"
      ];
    };
  };

  weka.tailscaleServices.paperless = port;

  # The scanner writes into consume as itself; setgid and group-writable so
  # Paperless (group paperless) can read and then delete what it's taken in.
  # Overrides the module's rule, which would put it back to 755 on every boot.
  users.users.scanner = {
    isSystemUser = true;
    group = "paperless";
    hashedPasswordFile = config.sops.secrets.scanner_password_hash.path;
  };
  systemd.tmpfiles.settings."10-paperless".${cfg.consumptionDir}.d = lib.mkForce {
    inherit (cfg) user;
    group = "paperless";
    mode = "2770";
  };

  services.vsftpd = {
    enable = true;
    localUsers = true;
    writeEnable = true;
    userlistEnable = true;
    userlistDeny = false;
    userlist = [ "scanner" ];
    chrootlocalUser = true;
    allowWriteableChroot = true;
    localRoot = cfg.consumptionDir;
    extraConfig = ''
      local_umask=007
      pasv_min_port=${toString passive.from}
      pasv_max_port=${toString passive.to}
    '';
  };
  # The module only declares a PAM service for virtual users. Without one,
  # local logins fall through to pam "other", which denies everything.
  security.pam.services.vsftpd = { };

  networking.firewall.interfaces.lan0 = {
    allowedTCPPorts = [ 21 ];
    allowedTCPPortRanges = [ passive ];
  };
}
