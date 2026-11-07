# Homepage at https://home.tarpan-krait.ts.net: a start page for everything
# weka serves over Tailscale. It has no login of its own; Tailscale is the
# access control, same as every other service here.
#
# The service list is generated from weka.tailscaleServices, so anything new
# turns up on its own (under "Other", with a link and an up/down dot). Add an
# entry to `meta` below to give it a group, icon, description or widget, or a
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
    { name = "Monitoring"; columns = 3; }
    { name = "Other"; columns = 3; }
  ];

  promMetric = label: query: format: { inherit label query format; };
  ago = { type = "relativeDate"; scale = 1000; };

  # Icons by name come from https://github.com/homarr-labs/dashboard-icons,
  # loaded by the browser from a CDN.
  meta = {
    mealie = { group = "Apps"; description = "Recipes and meal plans"; };
    paperless = {
      group = "Apps";
      description = "Scanned documents";
      icon = "paperless-ngx.svg";
    };
    readeck = {
      group = "Apps";
      description = "Saved articles";
      # / redirects to the https base_url, which the monitor won't follow
      monitorPath = "/api/info";
    };
    grafana = {
      group = "Monitoring";
      description = "Dashboards and logs";
      widget = {
        type = "prometheusmetric";
        url = promUrl;
        refreshInterval = 60000;
        metrics = [
          (promMetric "Last backup" "max(restic_last_success_timestamp_seconds)" ago)
          (promMetric "Last snapshot" "max(zfs_newest_snapshot_timestamp_seconds)" ago)
          (promMetric "Pool used" "max(zfs_pool_used_ratio)" { type = "percent"; scale = 100; options.maximumFractionDigits = 0; })
          (promMetric "Pool errors" "sum(zfs_pool_errors)" { type = "number"; })
        ];
      };
    };
    prometheus = {
      group = "Monitoring";
      description = "Metrics and alert rules";
      widget = { type = "prometheus"; url = promUrl; };
    };
    alertmanager = {
      group = "Monitoring";
      description = "Alerts and silences";
      widget = {
        type = "prometheusmetric";
        url = promUrl;
        metrics = [
          (promMetric "Firing" ''count(ALERTS{alertstate="firing",alertname!="Watchdog"}) or vector(0)'' { type = "number"; })
          (promMetric "Silenced" ''sum(alertmanager_alerts{state="suppressed"}) or vector(0)'' { type = "number"; })
        ];
      };
    };
  };

  services = lib.removeAttrs config.weka.tailscaleServices [ "home" ];
  card = name: svcPort:
    let m = meta.${name} or { }; in {
      ${m.title or (lib.toUpper (lib.substring 0 1 name) + lib.substring 1 (-1) name)} = {
        href = "https://${name}.${tailnet}";
        icon = m.icon or "${name}.svg";
        # Straight to the app, not through Tailscale
        siteMonitor = "http://127.0.0.1:${toString svcPort}${m.monitorPath or ""}";
      }
      // lib.optionalAttrs (m ? description) { inherit (m) description; }
      // lib.optionalAttrs (m ? widget) { inherit (m) widget; };
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

  # The module leaves HOSTNAME unset, and Homepage then listens on 0.0.0.0.
  # The firewall would block it, but keep it on localhost like everything else.
  systemd.services.homepage-dashboard.environment.HOSTNAME = "127.0.0.1";

  weka.tailscaleServices.home = port;
}
