{ pkgs, ... }: {
  config.project.name = "self hosted services";
  config.services = {
    # Thoughts:
    # - this could easily be decomposed into multiple nix files (yay)
    # - or it could be generated from a tangled org file (neat, but no linting/formatting)
    # - it's completely indendent from the main config (yay!)

    # Usage (it's mostly like docker-compose):
    # - all up: `arion up -d`
    # - show statuses: `arion ps`
    # - start/stop/down all: `arion <start/stop/down>`
    # - start single service: `arion start <service>`

    # caddy setup
    entry-point = {
      service.useHostStore = true;
      service.ports = [ "80:80" "2019:2019" ];
      service.capabilities.SYS_ADMIN = true;

      nixos.useSystemd = true;
      nixos.configuration.boot.tmpOnTmpfs = true;

      nixos.configuration.services.caddy = {
        enable = true;
        virtualHosts."http://test.h.jackrose.co.nz" = {
          extraConfig = ''
            reverse_proxy mealie:80
          '';
        };
      };
    };

    # an example to test out hosting a docker container
    mealie = {
      service.image = "hkotel/mealie:v0.5.6";
    };
  };
}
