# Usage (it's mostly like docker-compose):
# - all up: `arion up -d`
# - show statuses: `arion ps`
# - start/stop/down all: `arion <start/stop/down>`
# - start single service: `arion start <service>`

{ pkgs, ... }:
let
  projectName = "shs";
  basePath = "/var/lib/shs/";
  caddyfile = builtins.toFile "Caddyfile" ''
    {
      admin off
      email "user+acme@jackrose.co.nz"
    }

    mealie.h.jackrose.co.nz {
      reverse_proxy mealie:80
    }
  '';
in
{
  config.project.name = projectName;
  config.services = {
    # Reverse proxy
    caddy = {
      image = {
        nixBuild = true;
        enableRecommendedContents = true;
        command = [ "${pkgs.caddy}/bin/caddy" "run" "--config=${caddyfile}" "--adapter=caddyfile" ];
        contents = [ pkgs.cacert ];
      };
      service = {
        container_name = "${projectName}-caddy";
        useHostStore = true;
        ports = [ "80:80" "443:443" "25565:25565" ];
        volumes = [ "${basePath}/caddy-data:/.local/share/caddy" ];
      };
    };

    mealie.service = {
      container_name = "${projectName}-mealie";
      image = "hkotel/mealie:v0.5.6";
      volumes = [ "${basePath}/mealie-data:/app/data" ];
      environment = {
        TZ = "Australia/Melbourne";
      };
    };

  };
}
