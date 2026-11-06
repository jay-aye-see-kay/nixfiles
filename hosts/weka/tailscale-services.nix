# Tailscale Services on weka: https://<name>.tarpan-krait.ts.net, TLS terminated
# by Tailscale, proxied to a plain HTTP port on localhost.
#
# Not services.tailscale.serve: its config file (tailscale serve set-config)
# uses the target's scheme for both sides, so "http://" serves plain HTTP on
# 443 and "https://" talks TLS to the backend too. HTTPS in front of HTTP needs
# the CLI (checked against tailscale 1.98).
#
# Each service also has to be defined in the admin console (tcp:443, tag
# tag:weka-svc, which auto-approves tag:server hosts). Define it before
# deploying. Removing an entry here doesn't stop serving it, so run
# `tailscale serve clear svc:<name>` by hand.
# @see: https://tailscale.com/docs/features/tailscale-services
{ config, lib, ... }:
let
  cfg = config.weka.tailscaleServices;
  tailscale = lib.getExe config.services.tailscale.package;
in
{
  options.weka.tailscaleServices = lib.mkOption {
    type = lib.types.attrsOf lib.types.port;
    default = { };
    example = { readeck = 8000; };
    description = "Service name to the localhost HTTP port it proxies to.";
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
        (name: port: ''
          ${tailscale} serve clear svc:${name} || true
          ${tailscale} serve --bg --service=svc:${name} --https=443 http://127.0.0.1:${toString port}
        '')
        cfg);
    };
  };
}
