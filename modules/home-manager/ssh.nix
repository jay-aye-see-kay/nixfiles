{ config, lib, ... }:
let
  cfg = config.modules.ssh;

  # Groups of SSH hosts. Enable the groups a machine should know about via
  # `modules.ssh.groups`
  hostGroups = {
    # all desktops/laptops
    common = {
      pi1 = {
        User = "jack";
        HostName = "192.168.1.41";
      };
      pi2 = {
        User = "jack";
        HostName = "192.168.1.42";
      };
    };

    # non work stuff
    personal = {
      vaccum = {
        User = "root";
        HostName = "192.168.50.200";
        IdentityAgent = "~/.1password/agent.sock";
      };

      pm1 = {
        User = "root";
        HostName = "192.168.1.72";
        Port = 22;
      };
      pm1-boot-unlock = {
        User = "root";
        HostName = "192.168.1.72";
        Port = 2233;
      };

      crafty = {
        User = "jack";
        HostName = "192.168.30.100";
        Port = 22;
      };

      honey = {
        User = "root";
        HostName = "192.168.30.102";
        Port = 22;
      };

      innie = {
        User = "jack";
        HostName = "192.168.10.105";
        Port = 22;
      };

      al = {
        User = "jack";
        HostName = "192.168.10.106";
        Port = 22;
      };
    };
  };
in
{
  options.modules.ssh = {
    enable = lib.mkEnableOption "ssh client config";

    groups = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (lib.attrNames hostGroups));
      default = [ ];
      example = [ "common" "personal" ];
      description = "Which groups of hosts to include in ~/.ssh/config.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings = lib.mkMerge (map (g: hostGroups.${g}) cfg.groups);
    };
  };
}
