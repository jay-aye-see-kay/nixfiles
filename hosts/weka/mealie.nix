# Mealie, reached only over Tailscale at https://mealie.tarpan-krait.ts.net
# (a Tailscale Service, see tailscale-services.nix). SQLite, and its secrets
# (.secret, .session_secret) live in the data dir, so nothing in sops. Data is
# its own ZFS dataset, rpool/crypt/data/mealie (see disko.nix).
# @see: https://docs.mealie.io/documentation/getting-started/installation/backend-config/
{ pkgs-unstable, ... }:
let
  port = 9000;
in
{
  services.mealie = {
    enable = true;
    # Unstable, as on honey: the data came from 3.20.1 and stable has 3.16.
    # Never go back to an older version than the data has seen.
    package = pkgs-unstable.mealie;
    listenAddress = "127.0.0.1";
    inherit port;
    settings = {
      ALLOW_SIGNUP = "false";
      BASE_URL = "https://mealie.tarpan-krait.ts.net";
    };
  };

  # Don't start on an empty dir if the dataset isn't mounted (see disko.nix)
  systemd.services.mealie.unitConfig.RequiresMountsFor = [ "/var/lib/private/mealie" ];

  weka.tailscaleServices.mealie = port;
}
