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

    jellyfin.h.jackrose.co.nz {
      reverse_proxy jellyfin:8096
    }

    nextcloud.h.jackrose.co.nz {
      reverse_proxy nextcloud:80
    }
  '';
in
{
  config.project.name = projectName;
  config.services = {
    # Reverse proxy
    caddy = {
      image = {
        enableRecommendedContents = true;
        command = [ "${pkgs.caddy}/bin/caddy" "run" "--config=${caddyfile}" "--adapter=caddyfile" ];
        contents = [ pkgs.cacert ];
      };
      service = {
        container_name = "${projectName}-caddy";
        ports = [ "80:80" "443:443" "25565:25565" ];
        volumes = [ "${basePath}/caddy-data:/.local/share/caddy" ];
      };
    };

    # Mealie (recipes)
    mealie.service = {
      container_name = "${projectName}-mealie";
      image = "hkotel/mealie:latest";
      volumes = [ "${basePath}/mealie-data:/app/data" ];
      environment = {
        TZ = "Australia/Melbourne";
      };
    };

    # Jellyfin (video)
    jellyfin.service = {
      container_name = "${projectName}-jellyfin";
      image = "jellyfin/jellyfin:latest";
      volumes = [
        "${basePath}/jellyfin-data:/config"
        "/tmp/jellyfin-cache:/cache"
        "/media/tv:/tv:ro"
        "/media/movies:/movies:ro"
      ];
      environment = {
        TZ = "Australia/Melbourne";
      };
    };

    # Nextcloud (file share and sync)
    nextcloud.service = {
      container_name = "${projectName}-nextcloud";
      image = "nextcloud:24";
      volumes = [ "${basePath}/nextcloud-data:/var/www/html" ];
      environment = {
        TZ = "Australia/Melbourne";
        POSTGRES_USER = "postgres";
        POSTGRES_PASSWORD = "\${POSTGRES_PASSWORD:?required}";
        POSTGRES_DB = "nextcloud";
        POSTGRES_HOST = "nextcloud-db";
        REDIS_HOST = "nextcloud-redis";
      };
    };
    nextcloud-db.service = {
      container_name = "${projectName}-nextcloud-db";
      image = "postgres:14";
      volumes = [ "${basePath}/nextcloud-db:/var/lib/postgresql/data" ];
      environment = {
        POSTGRES_USER = "postgres";
        POSTGRES_PASSWORD = "\${POSTGRES_PASSWORD:?required}";
        POSTGRES_DB = "nextcloud";
      };
    };
    nextcloud-redis.service = {
      container_name = "${projectName}-nextcloud-redis";
      image = "redis:7";
    };
  };
}
