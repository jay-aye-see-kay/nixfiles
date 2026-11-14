# Valetudo (the rooted robot vacuum's web UI) at https://vacuum.tarpan-krait.ts.net.
# The robot can't run Tailscale sensibly, so weka proxies to it over the LAN:
# Tailscale Service -> nginx on localhost -> robot. nginx is only there because
# `tailscale serve` only accepts localhost targets.
#
# Home Assistant doesn't use this: the robot talks to it over MQTT. The robot is
# still reachable directly on the LAN at its own IP.
# @see: https://valetudo.cloud/
{ lib, ... }:
let
  port = 8090;
  robot = "192.168.50.200";

  # Valetudo's REST API, through the nginx proxy below. No auth.
  # @see: https://valetudo.cloud/pages/usage/rest-api.html
  valetudoApi = "http://127.0.0.1:${toString port}/api/v2/robot";
  capitalise = value: { inherit value; to = lib.toUpper (lib.substring 0 1 value) + lib.substring 1 (-1) value; };
  # Consumable minutes left, shown in hours
  consumable = label: index: {
    inherit label;
    field = "${toString index}.remaining.value";
    format = "number";
    scale = "1/60";
    suffix = "h";
  };
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
  weka.homepage.vacuum = {
    group = "Apps";
    description = "Robot vacuum (Valetudo)";
    icon = "valetudo.svg";
    # The API returns arrays, and customapi can only pick by position, so
    # these indexes follow the order the robot reports things in. If a
    # block shows the wrong thing, check the order with curl on weka.
    widgets = [
      {
        type = "customapi";
        url = "${valetudoApi}/state/attributes";
        refreshInterval = 10000;
        mappings = [
          {
            label = "Status";
            field = "5.value";
            remap = map capitalise [ "docked" "idle" "cleaning" "returning" "paused" "error" "manual_control" "moving" ];
          }
          { label = "Battery"; field = "3.level"; format = "percent"; }
          { label = "Dock"; field = "1.value"; remap = map capitalise [ "idle" "pause" "emptying" "drying" "washing" "cleaning" "error" ]; }
        ];
      }
      {
        type = "customapi";
        url = "${valetudoApi}/capabilities/ConsumableMonitoringCapability";
        refreshInterval = 300000;
        mappings = [
          (consumable "Main brush" 0)
          (consumable "Side brush" 1)
          (consumable "Filter" 2)
        ];
      }
    ];
  };
}
