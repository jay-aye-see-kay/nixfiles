{ config, pkgs, ... }:
let
  user = "jack";
  devices = {
    "possum" = { id = "4L6CALJ-X7QC2TU-GAXT7AD-EG7IDTM-YSBOHHA-WZ576MI-O4SXB5M-ECQTTAL"; };
    "tui" = { id = "3EEYNSK-IJ4YIX3-PHIEKT7-OECJJ2K-7RZAEZ7-TBY2AGW-HCKNPNH-34QYTQ6"; };
    "jjack-XMW16X" = { id = "IMQF5KD-ZGCQOZQ-GWPFWSN-2E3FH3O-UFOJL2Z-DBTS2AU-NVVAVYJ-XYNLJAG"; };
  };
  allDevices = ["possum" "tui" "jjack-XMW16X"];
in
{
  services.syncthing = {
    inherit user devices;
    enable = true;
    group = "users";
    dataDir = "/home/${user}/Sync"; # Default folder for new synced folders
    configDir = "/home/${user}/.config/syncthing"; # Folder for Syncthing's settings and keys
    guiAddress = "localhost:8384";
    overrideDevices = true;
    overrideFolders = true;
    folders = {
      Default = {
        path = "/home/jack/Sync";
        devices = allDevices;
      };
      Notes = {
        path = "/home/jack/notes";
        devices = allDevices;
      };
      "Documents" = {
        path = "/home/jack/Documents";
        devices = allDevices;
      };
      "Calibre library" = {
        path = "/home/jack/Calibre Library";
        devices = allDevices;
      };
    };
  };
}
