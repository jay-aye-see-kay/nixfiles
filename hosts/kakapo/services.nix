{ pkgs, ... }:
let
  caddyfile = pkgs.writeText "Caddyfile" ''
    test.h.jackrose.co.nz {
    	reverse_proxy webserver:8000
    }
  '';
in
{
  project.name = "testing_web_apps";
  services = {
    caddy.service = {
      image = "caddy:latest";
      volumes = [
        "${caddyfile}:/etc/caddy/Caddyfile"
        # "/hs/caddy/data:/data"
        # if this wasn't a test we'd want to perist SSL cert data somewhere
      ];
      ports = [ "80:80" "443:443" ];
    };

    webserver = {
      image.enableRecommendedContents = true;
      service = {
        useHostStore = true;
        command = [
          "sh"
          "-c"
          ''cd "$$WEB_ROOT" && ${pkgs.python3}/bin/python -m http.server''
        ];
        environment.WEB_ROOT = "${pkgs.nix.doc}/share/doc/nix/manual";
        stop_signal = "SIGINT";
      };
    };
  };
}
