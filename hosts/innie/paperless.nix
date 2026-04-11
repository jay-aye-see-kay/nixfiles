{ config, lib, pkgs, ... }:

{
  environment.etc."paperless-admin-pass".text = "admin";

  # Add paperless user to rose group for Samba compatibility
  users.users.paperless.extraGroups = [ "rose" ];

  services.paperless = {
    enable = true;
    address = "0.0.0.0";  # Listen on all interfaces for LAN access
    mediaDir = "/srv/data/paperless-media";  # Store documents on HDD
    passwordFile = "/etc/paperless-admin-pass";
    settings = {
      PAPERLESS_OCR_LANGUAGE = "eng";
      PAPERLESS_CONSUMER_IGNORE_PATTERN = [
        ".DS_STORE/*"
        "desktop.ini"
        "*.tmp"
      ];
    };
  };

  # FTP server for Brother scanner -> paperless consumption dir
  services.vsftpd = {
    enable = true;
    localUsers = true;
    writeEnable = true;
    chrootlocalUser = true;
    allowWriteableChroot = true;
    localRoot = config.services.paperless.consumptionDir;  # /var/lib/paperless/consume
    extraConfig = ''
      pasv_min_port=50000
      pasv_max_port=50100
    '';
  };

  # Open FTP + Paperless web UI ports
  networking.firewall = {
    allowedTCPPorts = [ 21 28981 ];
    allowedTCPPortRanges = [{ from = 50000; to = 50100; }];
  };
}
