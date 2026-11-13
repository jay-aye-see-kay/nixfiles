{ config, lib, pkgs, ... }:
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
      vacuum = {
        User = "root";
        HostName = "192.168.50.200";
        IdentityAgent =
          if pkgs.stdenv.isDarwin then
            ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"''
          else
            "~/.1password/agent.sock";
      };

      # weka's initrd SSH: logging in drops into the root passphrase prompt
      weka-unlock = {
        User = "root";
        HostName = "192.168.10.101";
        Port = 2222;
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
