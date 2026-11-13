# Tailscale Services on weka: https://<name>.tarpan-krait.ts.net, TLS terminated
# by Tailscale, proxied to a plain HTTP port (on localhost unless a host is given).
#
# Not services.tailscale.serve: its config file (tailscale serve set-config)
# uses the target's scheme for both sides, so "http://" serves plain HTTP on
# 443 and "https://" talks TLS to the backend too. HTTPS in front of HTTP needs
# the CLI (checked against tailscale 1.98).
#
# Each service also has to be defined in the admin console (tcp:443, tag
# tag:weka-svc, which auto-approves tag:server hosts). Define it before
# deploying. If weka advertised it first, defining it later approves weka
# (its log stops asking for approval) but clients never get the route: the
# name resolves and then times out. Re-advertise to fix it, on weka:
#   tailscale serve drain svc:<name> && tailscale serve advertise svc:<name>
# Removing an entry here doesn't stop serving it, so run
# `tailscale serve clear svc:<name>` by hand.
# @see: https://tailscale.com/docs/features/tailscale-services
{ config, lib, ... }:
let
  cfg = config.weka.tailscaleServices;
  tailscale = lib.getExe config.services.tailscale.package;
in
{
  options.weka.tailscaleServices = lib.mkOption {
    # A bare port means 127.0.0.1. A host is for apps that aren't on the
    # host's loopback, like the ones in the VPN namespace (arr.nix).
    type = lib.types.attrsOf (lib.types.coercedTo lib.types.port (port: { inherit port; })
      (lib.types.submodule {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
          };
          port = lib.mkOption { type = lib.types.port; };
        };
      }));
    default = { };
    example = { readeck = 8000; sonarr = { host = "192.168.15.1"; port = 8989; }; };
    description = "Service name to the HTTP address it proxies to.";
  };

  config = lib.mkIf (cfg != { }) {
    systemd.services.tailscale-services = {
      description = "Tailscale Services (serve and advertise)";
      after = [ "tailscaled.service" ];
      wants = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # tailscaled can take a moment to come up at boot
        Restart = "on-failure";
        RestartSec = 5;
      };
      script = lib.concatStrings (lib.mapAttrsToList
        (name: svc: ''
          ${tailscale} serve clear svc:${name} || true
          ${tailscale} serve --bg --service=svc:${name} --https=443 http://${svc.host}:${toString svc.port}
        '')
        cfg);
    };
  };
}
