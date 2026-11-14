# Readeck, reached only over Tailscale at https://readeck.tarpan-krait.ts.net
# (a Tailscale Service, see platform/tailscale-services.nix). Data is its own ZFS dataset,
# rpool/crypt/data/readeck (see base/disko.nix).
# @see: https://readeck.org/en/docs/configuration
{ config, ... }:
let
  port = 8000;
in
{
  sops.secrets.readeck_env = { };

  services.readeck = {
    enable = true;
    # READECK_SECRET_KEY. Also stops Readeck generating one and trying to
    # write it back into its read-only config.
    environmentFile = config.sops.secrets.readeck_env.path;
    settings = {
      server.host = "127.0.0.1";
      server.port = port;
      server.base_url = "https://readeck.tarpan-krait.ts.net";
      # tailscaled proxies from localhost
      server.trusted_proxies = [ "127.0.0.1" ];
    };
  };

  weka.tailscaleServices.readeck = port;
}
