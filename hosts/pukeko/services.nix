{ config, pkgs, lib, ... }:
let
  # Add this string to any host's caddy config to put it behind auth
  ports = {
    authelia = "9091";
    syncthingGui = "8384";
    silverbullet = "2001";
    gossa = "2002";
  };
  authConfg = ''
    forward_auth localhost:${ports.authelia} {
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

  # {{{ auth
  services.caddy.virtualHosts."auth.p.jackrose.co.nz" = {
    extraConfig = "reverse_proxy localhost:${ports.authelia}";
  };
  # }}}

  # {{{ syncthing
  services.caddy.virtualHosts."syncthing.p.jackrose.co.nz" = {
    extraConfig = authConfg + ''
      reverse_proxy http://localhost:${ports.syncthingGui} {
          header_up Host {upstream_hostport}
      }
    '';
  };
  # }}}

  # {{{ gossa (file ui)
  services.caddy.virtualHosts."files.p.jackrose.co.nz" = {
    extraConfig = authConfg + "reverse_proxy http://localhost:${ports.gossa}";
  };
  systemd.services.gossa = {
    enable = true;
    description = "serve files in homedir on port ${ports.gossa}";
    unitConfig = {
      Type = "simple";
    };
    serviceConfig = {
      ExecStart = "${pkgs.unstable.gossa}/bin/gossa -p=${ports.gossa} /home/jack";
      User = "jack";
      Group = "users";
    };
    wantedBy = [ "multi-user.target" ];
  };
  # }}}

  # {{{ freshrss
  services.caddy.virtualHosts."freshrss.p.jackrose.co.nz" = {
    extraConfig = authConfg + ''
      root * ${pkgs.freshrss}/p
      php_fastcgi unix/${config.services.phpfpm.pools.freshrss.socket} {
          env FRESHRSS_DATA_PATH ${config.services.freshrss.dataDir}
      }
      file_server
    '';
  };
  services.freshrss = {
    enable = true;
    package = pkgs.unstable.freshrss;
    passwordFile = "/var/lib/freshrss/adminPassword";
    baseUrl = "https://freshrss.p.jackrose.co.nz";
    virtualHost = null;
  };
  services.phpfpm.pools.freshrss.settings = {
    # use the provided phpfpm pool, but override permissions for caddy
    "listen.owner" = lib.mkForce "caddy";
    "listen.group" = lib.mkForce "caddy";
  };
  # }}}

  # {{{ silverbullet (markdown web viewer)
  services.caddy.virtualHosts."silverbullet.p.jackrose.co.nz" = {
    extraConfig = authConfg + ''
      reverse_proxy localhost:${ports.silverbullet}
    '';
  };
  systemd.services.silverbullet =
    let
      version = "0.3.9";
      silverbullet-js-file = pkgs.fetchurl {
        url = "https://github.com/silverbulletmd/silverbullet/releases/download/${version}/silverbullet.js";
        # sha256 = lib.fakeSha256; # to get new hash
        sha256 = "sha256-n8BQCq2vLWAx0rq2Kw8MZGQNPu457oUuROCUnMcXjkU=";
      };
      silverbullet = pkgs.writeShellScriptBin "silverbullet"
        "${pkgs.deno}/bin/deno run -A --unstable ${silverbullet-js-file} $@";
    in
    {
      enable = true;
      description = "silverbullet.md serving my notes on port ${ports.silverbullet}";
      unitConfig = {
        Type = "simple";
      };
      serviceConfig = {
        ExecStart = "${silverbullet}/bin/silverbullet --port ${ports.silverbullet} /home/jack/notes";
        User = "jack";
        Group = "users";
      };
      wantedBy = [ "multi-user.target" ];
    };
  # }}}
}
