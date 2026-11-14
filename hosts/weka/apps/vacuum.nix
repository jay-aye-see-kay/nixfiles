# Valetudo (the rooted robot vacuum's web UI) at https://vacuum.tarpan-krait.ts.net.
# The robot can't run Tailscale sensibly, so weka proxies to it over the LAN:
# Tailscale Service -> nginx on localhost -> robot. nginx is only there because
# `tailscale serve` only accepts localhost targets.
#
# Home Assistant doesn't use this: the robot talks to it over MQTT. The robot is
# still reachable directly on the LAN at its own IP.
# @see: https://valetudo.cloud/
{ ... }:
let
  port = 8090;
  robot = "192.168.50.200";
in
{
  services.nginx = {
    enable = true;
    virtualHosts.vacuum = {
      listen = [{ addr = "127.0.0.1"; inherit port; }];
      locations."/" = {
        proxyPass = "http://${robot}";
        proxyWebsockets = true;
        extraConfig = ''
          # The UI streams live state and map updates as server-sent events
          proxy_buffering off;
          proxy_read_timeout 1h;
        '';
      };
    };
  };

  weka.tailscaleServices.vacuum = port;
}
