{ config, lib, pkgs, ... }:

{
  # Samba NAS - public guest share
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "innie";
        "netbios name" = "innie";
        security = "user";
        "hosts allow" = "192.168. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      public = {
        path = "/srv/public";
        browseable = "yes";
        "read only" = "no";
        writable = "yes";
        "guest ok" = "yes";
        "create mask" = "0664";
        "directory mask" = "0775";
        "force user" = "nobody";
        "force group" = "nogroup";
        "vfs objects" = "catia fruit streams_xattr"; # macos compat
      };
    };
  };

  # Windows discovery
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  # macOS/Linux discovery via mDNS
  services.avahi = {
    enable = true;
    openFirewall = true;
    publish.enable = true;
    publish.userServices = true;
    nssmdns4 = true;
  };
}
