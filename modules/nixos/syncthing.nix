{ config, lib, ... }:
let
  cfg = config.modules.syncthing;
  user = "jack";
  devices = {
    "kakapo" = { id = "DGIBTJA-T3EI2NO-N324PUS-KSIKCWF-FDQXM64-TVOIFN2-W5KDAQB-Z3FNBQG"; };
    "tui" = { id = "3EEYNSK-IJ4YIX3-PHIEKT7-OECJJ2K-7RZAEZ7-TBY2AGW-HCKNPNH-34QYTQ6"; };
    "jjack-XMW16X" = { id = "IMQF5KD-ZGCQOZQ-GWPFWSN-2E3FH3O-UFOJL2Z-DBTS2AU-NVVAVYJ-XYNLJAG"; };
  };
  allDevices = [ "kakapo" "tui" "jjack-XMW16X" ];
  personalDevices = [ "kakapo" "tui" ];
  versioning = {
    type = "staggered";
    params = {
      cleanInterval = "3600";
      maxAge = "31536000";
    };
  };
in
{
  options.modules.syncthing = {
    enable = lib.mkEnableOption "Syncthing file synchronization";
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      inherit user;
      enable = true;
      group = "users";
      dataDir = "/home/${user}/Sync"; # Default folder for new synced folders
      configDir = "/home/${user}/.config/syncthing"; # Folder for Syncthing's settings and keys
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        inherit devices;
        folders = {
          Default = {
            inherit versioning;
            path = "/home/jack/Sync";
            devices = personalDevices;
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
    };
  };
}
