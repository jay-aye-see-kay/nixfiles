# Homepage at https://home.tarpan-krait.ts.net: a start page for everything
# weka serves over Tailscale. It has no login of its own; Tailscale is the
# access control, same as every other service here.
#
# The service list is generated from weka.tailscaleServices, so anything new
# turns up on its own (under "Other", with a link and an up/down dot). Add an
# entry to `meta` below to give it a group, icon, description or widgets, or a
# monitorPath if its / doesn't answer the up/down check with a plain 2xx/3xx.
# Widgets query the apps from the server side, so any API keys stay on weka.
# @see: https://gethomepage.dev/configs/services/
# @see: https://gethomepage.dev/widgets/
{ config, lib, ... }:
let
  port = 8082;
  tailnet = "tarpan-krait.ts.net";
  promUrl = "http://127.0.0.1:${toString config.services.prometheus.port}";

  # Groups, in display order, and how many cards per row
  groups = [
    { name = "Apps"; columns = 3; }
    { name = "Downloads"; columns = 4; }
    { name = "Monitoring"; columns = 3; }
    { name = "Other"; columns = 3; }
  ];

  promMetric = label: query: format: { inherit label query format; };
  # One row of up to 4 Prometheus queries; a card can stack several
  promRow = metrics: { type = "prometheusmetric"; url = promUrl; refreshInterval = 60000; inherit metrics; };
  ago = { type = "relativeDate"; scale = 1000; };

  # Valetudo's REST API, through the nginx proxy in vacuum.nix. No auth.
  # @see: https://valetudo.cloud/pages/usage/rest-api.html
  valetudoApi = "http://127.0.0.1:8090/api/v2/robot";
  capitalise = value: { inherit value; to = lib.toUpper (lib.substring 0 1 value) + lib.substring 1 (-1) value; };
  # Consumable minutes left, shown in hours
  consumable = label: index: {
    inherit label;
    field = "${toString index}.remaining.value";
    format = "number";
    scale = "1/60";
    suffix = "h";
  };

  # The *arrs (arr.nix), in the VPN namespace. Homepage's own widget for
  # each, with the API key from sops (substituted from the environment).
  arrApps = {
    prowlarr = "Indexers";
    sonarr = "TV";
    radarr = "Films";
    lidarr = "Music";
  };
  arrMeta = lib.mapAttrs
    (app: description:
      let svc = config.weka.tailscaleServices.${app}; in {
        group = "Downloads";
        inherit description;
        widgets = [{
          type = app;
          url = "http://${svc.host}:${toString svc.port}";
          key = "{{HOMEPAGE_VAR_${lib.toUpper app}_KEY}}";
        }];
      })
    arrApps;

  # Icons by name come from https://github.com/homarr-labs/dashboard-icons,
  # loaded by the browser from a CDN.
  meta = arrMeta // {
    # No credentials: the widget only logs in after a 403, and qBittorrent
    # lets weka's bridge address in without one (arr.nix).
    qbittorrent = {
      group = "Downloads";
      title = "qBittorrent";
      description = "Torrents";
      widgets = [{
        type = "qbittorrent";
        url = let svc = config.weka.tailscaleServices.qbittorrent; in "http://${svc.host}:${toString svc.port}";
      }];
    };
    home-assistant = {
      group = "Apps";
      title = "Home Assistant";
      description = "Home automation";
    };
    jellyfin = { group = "Apps"; description = "Films and TV"; };
    mealie = { group = "Apps"; description = "Recipes and meal plans"; };
    paperless = {
      group = "Apps";
      description = "Scanned documents";
      icon = "paperless-ngx.svg";
    };
    radicale = {
      group = "Apps";
      description = "Reminders inbox for the Mealie shopping list";
      # Everything else needs a Tailscale login (radicale.nix)
      monitorPath = "/.web/";
    };
    readeck = {
      group = "Apps";
      description = "Saved articles";
      # / redirects to the https base_url, which the monitor won't follow
      monitorPath = "/api/info";
    };
    vacuum = {
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
    grafana = {
      group = "Monitoring";
      description = "Dashboards and logs";
      widgets = [
        (promRow [
          (promMetric "Last backup" "max(restic_last_success_timestamp_seconds)" ago)
          (promMetric "Last snapshot" "max(zfs_newest_snapshot_timestamp_seconds)" ago)
          (promMetric "Last scrub" "max(zfs_pool_last_scrub_timestamp_seconds)" ago)
        ])
        (promRow [
          (promMetric "Pool used" "max(zfs_pool_used_ratio)" { type = "percent"; scale = 100; options.maximumFractionDigits = 0; })
          (promMetric "Pool errors" "sum(zfs_pool_errors)" { type = "number"; })
          # The resources widget counts ARC as used memory, so show how much it is
          (promMetric "ZFS ARC" "node_zfs_arc_size" { type = "bytes"; options.binary = true; })
        ])
      ];
    };
    prometheus = {
      group = "Monitoring";
      description = "Metrics and alert rules";
      widgets = [
        { type = "prometheus"; url = promUrl; }
        (promRow [
          (promMetric "Failed units" ''count(node_systemd_unit_state{state="failed"} == 1) or vector(0)'' { type = "number"; })
          (promMetric "NVMe temp" ''max(smartctl_device_temperature{temperature_type="current"})'' { type = "number"; suffix = "°C"; })
          (promMetric "NVMe wear" "max(smartctl_device_percentage_used)" { type = "percent"; })
        ])
      ];
    };
    alertmanager = {
      group = "Monitoring";
      description = "Alerts and silences";
      widgets = [
        (promRow [
          (promMetric "Firing" ''count(ALERTS{alertstate="firing",alertname!="Watchdog"}) or vector(0)'' { type = "number"; })
          (promMetric "Silenced" ''sum(alertmanager_alerts{state="suppressed"}) or vector(0)'' { type = "number"; })
        ])
      ];
    };
  };

  services = lib.removeAttrs config.weka.tailscaleServices [ "home" ];
  card = name: svc:
    let m = meta.${name} or { }; in {
      ${m.title or (lib.toUpper (lib.substring 0 1 name) + lib.substring 1 (-1) name)} = {
        href = "https://${name}.${tailnet}";
        icon = m.icon or "${name}.svg";
        # Straight to the app, not through Tailscale
        siteMonitor = "http://${svc.host}:${toString svc.port}${m.monitorPath or ""}";
      }
      // lib.optionalAttrs (m ? description) { inherit (m) description; }
      // lib.optionalAttrs (m ? widgets) { inherit (m) widgets; };
    };
  inGroup = group: lib.mapAttrsToList card
    (lib.filterAttrs (name: _: (meta.${name}.group or "Other") == group) services);
in
{
  services.homepage-dashboard = {
    enable = true;
    listenPort = port;
    allowedHosts = "home.${tailnet},127.0.0.1:${toString port},localhost:${toString port}";

    settings = {
      title = "weka";
      theme = "dark";
      color = "slate";
      headerStyle = "clean";
      statusStyle = "dot";
      hideVersion = true;
      disableUpdateCheck = true;
      layout = lib.listToAttrs (map
        (g: lib.nameValuePair g.name { style = "row"; inherit (g) columns; })
        groups);
    };

    services = lib.filter (g: lib.head (lib.attrValues g) != [ ])
      (map (g: { ${g.name} = inGroup g.name; }) groups);

    widgets = [
      {
        resources = {
          label = "weka";
          cpu = true;
          memory = true;
          uptime = true;
          cputemp = true;
          units = "metric";
          network = "lan0";
        };
      }
      {
        datetime = {
          text_size = "md";
          format = { dateStyle = "long"; timeStyle = "short"; hour12 = false; };
        };
      }
    ];

    bookmarks = [
      {
        Admin = [
          { Tailscale = [{ icon = "tailscale-light.svg"; href = "https://login.tailscale.com/admin/services"; }]; }
          { "Healthchecks.io" = [{ icon = "healthchecks.svg"; href = "https://healthchecks.io/"; }]; }
        ];
      }
    ];
  };

  sops.templates."homepage.env" = {
    content = lib.concatMapStrings
      (app: "HOMEPAGE_VAR_${lib.toUpper app}_KEY=${config.sops.placeholder."${app}_api_key"}\n")
      (lib.attrNames arrApps);
    restartUnits = [ "homepage-dashboard.service" ];
  };
  services.homepage-dashboard.environmentFiles = [ config.sops.templates."homepage.env".path ];

  # The module leaves HOSTNAME unset, and Homepage then listens on 0.0.0.0.
  # The firewall would block it, but keep it on localhost like everything else.
  systemd.services.homepage-dashboard.environment.HOSTNAME = "127.0.0.1";

  weka.tailscaleServices.home = port;
}
