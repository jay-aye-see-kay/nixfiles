{ pkgs, ... }:
{
  services.caddy.enable = true;

  services.caddy.virtualHosts."sb.p.jackrose.co.nz" = {
    extraConfig = ''
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

