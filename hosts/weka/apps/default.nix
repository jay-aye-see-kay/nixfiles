# One file (or directory) per app.
{
  imports = [
    ./readeck.nix
    ./mealie.nix
    ./radicale
    ./files.nix
    ./paperless.nix
    ./vacuum.nix
    ./home-assistant.nix
    ./jellyfin.nix
    ./plex.nix
    ./arr
  ];
}
