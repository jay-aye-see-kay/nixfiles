{ pkgs, ... }:
let
  authConfg = ''
    forward_auth localhost:9091 {
      uri /api/verify?rd=https://auth.p.jackrose.co.nz
      copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
    }
  '';
in
{
  imports = [
    ./authelia.nix
    ../../features/syncthing.nix
  ];

  services.caddy.enable = true;
  services.caddy.virtualHosts."auth.p.jackrose.co.nz" = {
    extraConfig = ''
      reverse_proxy localhost:9091
    '';
  };

  services.caddy.virtualHosts."syncthing.p.jackrose.co.nz" = {
    extraConfig = authConfg + ''
      reverse_proxy http://localhost:8384 {
            header_up Host {upstream_hostport}
      }
    '';
  };

  services.caddy.virtualHosts."sb.p.jackrose.co.nz" = {
    extraConfig = authConfg + ''
      reverse_proxy localhost:2001
    '';
  };

  systemd.services.silverbullet =
    let
      version = "0.2.11";
      silverbullet-js-file = pkgs.fetchurl {
        url = "https://github.com/silverbulletmd/silverbullet/releases/download/${version}/silverbullet.js";
        sha256 = "sha256-h0lASLNxJ5DZvaJbHpMI2PtRWCty1vPro1n8R5vHQME=";
      };
      silverbullet = pkgs.writeShellScriptBin "silverbullet"
        "${pkgs.deno}/bin/deno run -A --unstable ${silverbullet-js-file} $@";
    in
    {
      enable = true;
      description = "silverbullet.md serving my notes on port 2001";
      unitConfig = {
        Type = "simple";
      };
      serviceConfig = {
        ExecStart = "${silverbullet}/bin/silverbullet --port 2001 /home/jack/notes";
        User = "jack";
        Group = "users";
      };
      wantedBy = [ "multi-user.target" ];
    };
}

