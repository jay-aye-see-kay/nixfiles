{ pkgs, config, ... }:
{
  virtualisation.oci-containers.containers.minecraft-1 = {
    autoStart = true;
    image = "itzg/minecraft-server:java17";
    environment = {
      EULA = "TRUE";
      MAX_MEMORY = "3G";
      TYPE = "PAPER";
    };
    ports = [
      "25565:25565"
    ];
    volumes = [
      "/data/minecraft-1/data:/data"
    ];
  };
}
