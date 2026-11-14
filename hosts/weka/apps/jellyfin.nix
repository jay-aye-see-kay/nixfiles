# Jellyfin, the main media server, reached only over Tailscale at
# https://jellyfin.tarpan-krait.ts.net (a Tailscale Service, see
# platform/tailscale-services.nix). State is its own dataset,
# rpool/crypt/data/jellyfin. The media is on tank1 at
# /srv/media. The library stores absolute paths, so keep media there.
# @see: https://wiki.nixos.org/wiki/Jellyfin
let
  port = 8096;
in
{
  services.jellyfin = {
    enable = true;
    # Not on the LAN: every client (Apple TV included) has Tailscale
    openFirewall = false;
  };

  # /srv/media is nofail (base/tank1.nix). Without tank1, stay down rather than
  # scan an empty directory and drop the library.
  systemd.services.jellyfin.unitConfig.RequiresMountsFor = [ "/srv/media" ];

  weka.tailscaleServices.jellyfin = port;

  # Watch history, metadata, artwork. The media itself is on tank1.
  weka.datasets."data/jellyfin" = "/var/lib/jellyfin";
  weka.homepage.jellyfin = { group = "Apps"; description = "Films and TV"; };
}
