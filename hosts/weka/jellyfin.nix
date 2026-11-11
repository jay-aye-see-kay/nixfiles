# Jellyfin, the main media server, reached only over Tailscale at
# https://jellyfin.tarpan-krait.ts.net (a Tailscale Service, see
# tailscale-services.nix). State is its own dataset,
# rpool/crypt/data/jellyfin (see disko.nix). The media is on tank1 at
# /srv/media, the same paths it had on honey, so the library and watch
# history carried over as-is.
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

  # /srv/media is nofail (tank1.nix). Without tank1, stay down rather than
  # scan an empty directory and drop the library.
  systemd.services.jellyfin.unitConfig.RequiresMountsFor = [ "/srv/media" ];

  weka.tailscaleServices.jellyfin = port;
}
