{ config, pkgs, lib, ... }:
let
  utils = import ../utils.nix;
in
{
  # TODO does this "just work" with traefik out of the box?
  services.fail2ban.enable = true;

  # traefik base setup
  services.traefik.enable = true;
  services.traefik.staticConfigOptions = {
    api.insecure = true; # expose dashboard on 8080
    providers.docker.exposedByDefault = false;
    global = {
      checkNewVersion = false;
      sendAnonymousUsage = false;
    };
    entryPoints = {
      web = {
        address = ":80";
        http.redirections.entryPoint = {
          to = "websecure";
          scheme = "https";
        };
      };
      websecure.address = ":443";
      minecraft.address = ":25565";
    };
    certificatesResolvers.default.acme = {
      email = "user+acme@jackrose.co.nz";
      storage = "/data/traefik/acme.json";
      httpChallenge.entryPoint = "web";
    };
  };
  users.users.traefik.extraGroups = [ "docker" ];

  # traefik dashboard setup
  services.traefik.dynamicConfigOptions = lib.mkMerge [
    (utils.mkProtectedTraefikRoute "traefik" "http://127.0.0.1:8080")
    {
      http.middlewares.authelia.forwardAuth = {
        address = "https://auth.h.jackrose.co.nz/api/verify?rd=https://auth.h.jackrose.co.nz";
        trustForwardHeader = true;
        authResponseHeaders = "Remote-User, Remote-Groups, Remote-Name, Remote-Email";
      };
    }
  ];

  services.borgbackup.jobs.traefikBackup = {
    paths = "/data/traefik";
    repo = "/backups/traefik";
    doInit = true;
    encryption = {
      mode = "repokey";
      passCommand = "cat ${config.sops.secrets.borgPassword.path}";
    };
    compression = "auto,lzma";
    startAt = "hourly";
    prune.keep = {
      within = "1d"; # Keep all archives from the last day
      daily = 7; # keep 1 per day for a week
      weekly = 4;
      monthly = -1; # Keep at least one archive for each month
    };
  };

  networking.firewall = {
    allowedUDPPorts = [
      25565 # minecraft
      51820 # wireguard
    ];
    allowedTCPPorts = [
      80 # http
      443 # https
      25565 # minecraft
    ];
  };

  # connect nixos-containers to network
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "ens18";
  };

  imports = [
    ./authelia.nix
    ./homer.nix
    ./jellyfin.nix
    ./netdata.nix
    ./nextcloud.nix
    ./photoprism.nix
    ./servarr.nix
    ./tandoor.nix
  ];
}
