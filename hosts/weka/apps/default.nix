# One file (or directory) per app. Each one declares everything it needs:
# its Tailscale Service, dataset, Homepage card and secrets, so removing an
# app is deleting it and its line here. See README.md for the steps outside
# the repo.
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
