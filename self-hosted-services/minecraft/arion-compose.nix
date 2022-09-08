{ pkgs, lib, ... }:
let
  projectName = "mc";
  baseEnvConfig = {
    TZ = "Australia/Melbourne";
    EULA = "TRUE";
    MAX_MEMORY = "3G";
    TYPE = "PAPER";
    OVERRIDE_SERVER_PROPERTIES = "TRUE";
  };

  # for available versions see:
  # https://github.com/itzg/docker-minecraft-server#running-minecraft-server-on-different-java-version
  defaultJavaVersion = "java17";

  # define the worlds to host
  worlds = [
    {
      id = "rosalies-swamp";
      name = "Rosalie's Swamp";
    }
  ];

  defaultImage = "itzg/minecraft-server:java17";

  # make the mapping command for the router
  routerMappings = map ({ id, ... }: "${id}.mc.jackrose.co.nz=${id}:25565") worlds;
  routerCommand = "--mapping=" + (lib.concatStringsSep "," routerMappings);

  # make a minecraft world in a container
  makeMinecraftService = { id, name, envConfig ? { }, javaVersion ? defaultJavaVersion, ... }: {
    "${id}".service = {
      container_name = "${projectName}-${id}";
      image = "itzg/minecraft-server:${javaVersion}";
      restart = "unless-stopped";
      environment = baseEnvConfig
        // { MOTD = "${name}"; }
        // envConfig;
      volumes = [
        "/data/minecraft/${id}:/data"
      ];
    };
  };

  listOfMinecraftServices = map makeMinecraftService worlds;
  minecraftServices = lib.foldl (a: b: a // b) { } listOfMinecraftServices;
in
{
  config.project.name = projectName;
  config.services = {
    # Router/minecraft-specific reverse proxy
    router.service = {
      image = "itzg/mc-router";
      command = routerCommand;
      ports = [ "25565:25565" ];
      environment = {
        TZ = "Australia/Melbourne";
      };
    };
  } // minecraftServices;
}
