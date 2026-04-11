{ config, lib, pkgs, ... }:

{
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
      };
      data = {
        path = "/srv/data/family";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "jack nora";
        "create mask" = "0660";
        "directory mask" = "0770";
        "force group" = "rose";
        "vfs objects" = "catia fruit streams_xattr"; # macos compat
      };
      paperless = {
        path = "/srv/data/paperless-media";
        browseable = "yes";
        "read only" = "yes";
        "guest ok" = "no";
        "valid users" = "jack nora";
        "force group" = "rose";
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
