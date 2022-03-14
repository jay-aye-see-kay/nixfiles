{ pkgs, config, ... }:
let
  utils = import ../utils.nix;
in
{
  services.traefik.dynamicConfigOptions =
    utils.mkTraefikRoute "photoprism" "http://127.0.0.1:2342";

  virtualisation.oci-containers.containers.photoprism = {
    autoStart = true;
    image = "photoprism/photoprism";
    environment = {
      PHOTOPRISM_UPLOAD_NSFW = "true";
      PHOTOPRISM_ADMIN_PASSWORD = "change-me!";
    };
    extraOptions = [
      "--security-opt"
      "seccomp=unconfined"
      "--security-opt"
      "apparmor=unconfined"
    ];
    ports = [
      "2342:2342"
    ];
    volumes = [
      "/data/photoprism/data:/photoprism/storage" # storage folder for cache, database, and sidecar files (never remove)
      "/photos/main:/photoprism/originals" # original media files (photos and videos)
    ];
  };
}
