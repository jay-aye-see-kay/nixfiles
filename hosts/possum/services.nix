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
  imports = [ ./authelia.nix ];

  services.caddy.enable = true;
  services.caddy.virtualHosts."auth.p.jackrose.co.nz" = {
    extraConfig = ''
      reverse_proxy localhost:9091
    '';
  };

  services.caddy.virtualHosts."sb.p.jackrose.co.nz" = {
    extraConfig = authConfg + ''
      reverse_proxy localhost:2001
    '';
  };

  systemd.services.silverbullet = {
    enable = true;
    description = "silverbullet.md serving my notes on port 2001";
    unitConfig = {
      Type = "simple";
    };
    serviceConfig = {
      ExecStart = "${pkgs.silverbullet}/bin/silverbullet --port 2001 /srv/notes";
    };
    wantedBy = [ "multi-user.target" ];
  };
}

