# Mealie, reached only over Tailscale at https://mealie.tarpan-krait.ts.net
# (a Tailscale Service, see tailscale-services.nix), through nginx. SQLite,
# and its own secrets (.secret, .session_secret) live in the data dir. Data is
# its own ZFS dataset, rpool/crypt/data/mealie (see disko.nix).
# @see: https://docs.mealie.io/documentation/getting-started/installation/backend-config/
{ config, pkgs-unstable, ... }:
let
  port = 9000;
  proxyPort = 9010;
in
{
  # Shared secret for reverse proxy login, also used by the shopping list
  # sync (radicale.nix) to act as each person
  sops.secrets.mealie_proxy_secret = { };
  sops.templates."mealie.env" = {
    content = "REVERSE_PROXY_AUTH_SECRET=${config.sops.placeholder.mealie_proxy_secret}";
    restartUnits = [ "mealie.service" ];
  };
  sops.templates."mealie-nginx-secret.conf" = {
    content = ''proxy_set_header X-Mealie-Reverse-Proxy-Secret "${config.sops.placeholder.mealie_proxy_secret}";'';
    owner = config.services.nginx.user;
    reloadUnits = [ "nginx.service" ];
  };

  services.mealie = {
    enable = true;
    # Unstable: the data has already been migrated by 3.20, and stable has
    # 3.16. Never go back to an older version than the data has seen.
    package = pkgs-unstable.mealie;
    listenAddress = "127.0.0.1";
    inherit port;
    credentialsFile = config.sops.templates."mealie.env".path;
    settings = {
      ALLOW_SIGNUP = "false";
      BASE_URL = "https://mealie.tarpan-krait.ts.net";
      # Log in from the Tailscale identity, matched against the Mealie
      # username then email (so usernames are set to the tailnet login).
      # Mealie only trusts the header alongside the shared secret, which
      # nginx adds below, so another local process can't claim to be anyone.
      # Tagged devices get no header and see the password form.
      REVERSE_PROXY_AUTH_ENABLED = "true";
      REVERSE_PROXY_AUTH_HEADER = "Tailscale-User-Login";
    };
  };

  # Only here to add the secret: tailscale serve can't set custom headers
  services.nginx = {
    enable = true;
    virtualHosts.mealie = {
      listen = [{ addr = "127.0.0.1"; port = proxyPort; }];
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        extraConfig = ''
          include ${config.sops.templates."mealie-nginx-secret.conf".path};
          # Recipe images and backup uploads
          client_max_body_size 100m;
        '';
      };
    };
  };

  weka.tailscaleServices.mealie = proxyPort;
}
