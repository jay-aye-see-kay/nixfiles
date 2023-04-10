{ config, pkgs, ... }:
let
  user = "jack";
  devices = {
    "pukeko" = { id = "BVAQSV5-2LYW3VG-AS24HPV-ZG55NXM-2SMEHB5-3UZ7ZOJ-QLFLBTK-LP4BNQE"; };
    "tui" = { id = "3EEYNSK-IJ4YIX3-PHIEKT7-OECJJ2K-7RZAEZ7-TBY2AGW-HCKNPNH-34QYTQ6"; };
    "jjack-XMW16X" = { id = "IMQF5KD-ZGCQOZQ-GWPFWSN-2E3FH3O-UFOJL2Z-DBTS2AU-NVVAVYJ-XYNLJAG"; };
  };
  allDevices = [ "pukeko" "tui" "jjack-XMW16X" ];
  personalDevices = [ "pukeko" "tui" ];
  versioning = {
    type = "staggered";
    params = {
      cleanInterval = "3600";
      maxAge = "31536000";
    };
  };
in
{
  services.syncthing = {
    inherit user devices;
    enable = true;
    group = "users";
    dataDir = "/home/${user}/Sync"; # Default folder for new synced folders
    configDir = "/home/${user}/.config/syncthing"; # Folder for Syncthing's settings and keys
    overrideDevices = true;
    overrideFolders = true;
    folders = {
      Default = {
        inherit versioning;
        path = "/home/jack/Sync";
        devices = allDevices;
      };
      Notes = {
        inherit versioning;
        path = "/home/jack/notes";
        devices = allDevices;
      };
      "Documents" = {
        inherit versioning;
        path = "/home/jack/Documents";
        devices = allDevices;
      };
      "Calibre library" = {
        inherit versioning;
        path = "/home/jack/Calibre Library";
        devices = personalDevices;
      };
    };
  };
}
