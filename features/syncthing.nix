{ config, pkgs, ... }:
{
  # this config makes some big assumptions about how a host is setup, but because of how I use syncthing this is probably fine
  services.syncthing = {
    enable = true;
    user = "jack";
    group = "users";
    dataDir = "/home/jack/Sync"; # Default folder for new synced folders
    configDir = "/home/jack/.config/syncthing"; # Folder for Syncthing's settings and keys
    guiAddress = "localhost:8384";
    overrideDevices = true;
    overrideFolders = true;
    devices = {
      "possum" = { id = "4L6CALJ-X7QC2TU-GAXT7AD-EG7IDTM-YSBOHHA-WZ576MI-O4SXB5M-ECQTTAL"; };
      "tui" = { id = "3EEYNSK-IJ4YIX3-PHIEKT7-OECJJ2K-7RZAEZ7-TBY2AGW-HCKNPNH-34QYTQ6"; };
    };
    folders = {
      "/home/jack/Sync" = {
        # general folder for sync - goes to every device
        devices = [ "possum" "tui" ];
      };
      "/home/jack/notes" = {
        # my bucket of markdown files
        path = "/home/jack/notes";
        devices = [ "possum" "tui" ];
      };
    };
  };
}
