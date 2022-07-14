{ pkgs, lib, ... }:
let
  projectName = "mc";
  baseEnvConfig = {
    TZ = "Australia/Melbourne";
    EULA = "TRUE";
    MAX_MEMORY = "3G";
    TYPE = "PAPER";
    OVERRIDE_SERVER_PROPERTIES = "TRUE";

    ENABLE_AUTOPAUSE = "TRUE";
    # The maximum number of milliseconds a single tick may take before the server watchdog stops the
    # server with the message, disabled because we're using autopause.
    MAX_TICK_TIME = "-1";
    # default 600 (seconds) describes the time between server start and the pausing of the process,
    # when no client connects inbetween (read as timeout initialized)
    AUTOPAUSE_TIMEOUT_INIT = "60";
    # default 3600 (seconds) describes the time between the last client disconnect and the pausing
    # of the process (read as timeout established)
    AUTOPAUSE_TIMEOUT_EST = "60";
    # default 120 (seconds) describes the time between knocking of the port (e.g. by the main menu
    # ping) and the pausing of the process, when no client connects inbetween (read as timeout knocked)
    AUTOPAUSE_TIMEOUT_KN = "30";
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
    {
      id = "pixelmon";
      name = "Pixelmon";
      javaVersion = "java8";
      envConfig = {
        VERSION = "1.12.2";
        TYPE = "CURSEFORGE";
        CF_SERVER_MOD = "serverpack836.zip";
      };
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
        // { MOTD = "${name} [refresh before joining]"; }
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
