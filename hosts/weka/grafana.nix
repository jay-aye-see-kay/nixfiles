# Grafana at https://grafana.tarpan-krait.ts.net, reading from Prometheus.
#
# Dashboards are written here in Nix and provisioned read-only, so they're in
# git and a reinstall brings them back. To try something out, build it in the
# UI (save as a new dashboard), then copy the panel's query and settings back
# into a panel here. Its database (users, prefs, anything made in the UI) is on
# rpool/crypt/data/grafana, so it's snapshotted and backed up too.
# @see: home-server/MONITORING.md in dumpbox
{ config, lib, pkgs, ... }:
let
  port = 3000;
  domain = "grafana.tarpan-krait.ts.net";
  ds = { type = "prometheus"; uid = "prometheus"; };

  # Small panel helpers, so a dashboard reads as a list of queries
  thresholds = steps: {
    mode = "absolute";
    steps = lib.imap0
      (i: s: { color = s.color; value = if i == 0 then null else s.value; })
      steps;
  };
  stat = { title, expr, unit ? "none", steps ? [{ color = "green"; }], mappings ? [ ], x, y, w ? 4, h ? 4 }: {
    type = "stat";
    inherit title;
    datasource = ds;
    gridPos = { inherit x y w h; };
    targets = [{ inherit expr; refId = "A"; datasource = ds; instant = true; }];
    fieldConfig.defaults = { inherit unit mappings; thresholds = thresholds steps; color.mode = "thresholds"; };
    options = {
      reduceOptions.calcs = [ "lastNotNull" ];
      colorMode = "background";
      graphMode = "none";
      textMode = "value";
    };
  };
  graph = { title, targets, unit ? "none", x, y, w ? 12, h ? 8 }: {
    type = "timeseries";
    inherit title;
    datasource = ds;
    gridPos = { inherit x y w h; };
    targets = lib.imap0
      (i: t: { inherit (t) expr; legendFormat = t.legend; refId = lib.elemAt [ "A" "B" "C" "D" ] i; datasource = ds; })
      targets;
    fieldConfig.defaults = {
      inherit unit;
      custom = { fillOpacity = 10; showPoints = "never"; };
    };
    options.legend = { displayMode = "list"; placement = "bottom"; };
  };

  weka = {
    uid = "weka";
    title = "Weka";
    schemaVersion = 39;
    time = { from = "now-7d"; to = "now"; };
    refresh = "1m";
    panels = [
      (stat {
        title = "Alerts firing";
        expr = ''count(ALERTS{alertstate="firing",alertname!="Watchdog"}) or vector(0)'';
        steps = [{ color = "green"; } { color = "red"; value = 1; }];
        x = 0; y = 0;
      })
      (stat {
        title = "Pool";
        expr = "min(zfs_pool_online)";
        mappings = [{
          type = "value";
          options = {
            "1" = { text = "ONLINE"; color = "green"; };
            "0" = { text = "NOT ONLINE"; color = "red"; };
          };
        }];
        x = 4; y = 0;
      })
      (stat {
        title = "Last backup";
        expr = "time() - restic_last_success_timestamp_seconds";
        unit = "s";
        steps = [{ color = "green"; } { color = "orange"; value = 30 * 3600; } { color = "red"; value = 36 * 3600; }];
        x = 8; y = 0;
      })
      (stat {
        title = "Pool used";
        expr = "max(zfs_pool_used_ratio)";
        unit = "percentunit";
        steps = [{ color = "green"; } { color = "orange"; value = 0.75; } { color = "red"; value = 0.85; }];
        x = 12; y = 0;
      })
      (stat {
        title = "Memory used";
        expr = "1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes";
        unit = "percentunit";
        steps = [{ color = "green"; } { color = "orange"; value = 0.8; } { color = "red"; value = 0.9; }];
        x = 16; y = 0;
      })
      (stat {
        title = "Up for";
        expr = "time() - node_boot_time_seconds";
        unit = "s";
        steps = [{ color = "blue"; }];
        x = 20; y = 0;
      })

      (graph {
        title = "CPU";
        unit = "percentunit";
        targets = [{ expr = ''1 - avg(rate(node_cpu_seconds_total{mode="idle"}[$__rate_interval]))''; legend = "busy"; }];
        x = 0; y = 4;
      })
      (graph {
        title = "Memory";
        unit = "bytes";
        targets = [
          { expr = "node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes"; legend = "used"; }
          { expr = "node_zfs_arc_size"; legend = "ZFS cache (ARC)"; }
        ];
        x = 12; y = 4;
      })
      (graph {
        title = "Network";
        unit = "Bps";
        targets = [
          { expr = ''rate(node_network_receive_bytes_total{device="enp34s0"}[$__rate_interval])''; legend = "in"; }
          { expr = ''rate(node_network_transmit_bytes_total{device="enp34s0"}[$__rate_interval])''; legend = "out"; }
        ];
        x = 0; y = 12;
      })
      (graph {
        title = "Disk";
        unit = "Bps";
        targets = [
          { expr = ''rate(node_disk_read_bytes_total{device="nvme0n1"}[$__rate_interval])''; legend = "read"; }
          { expr = ''rate(node_disk_written_bytes_total{device="nvme0n1"}[$__rate_interval])''; legend = "write"; }
        ];
        x = 12; y = 12;
      })
      {
        type = "logs";
        title = "Errors in the journal";
        datasource = { type = "loki"; uid = "loki"; };
        gridPos = { x = 0; y = 20; w = 24; h = 10; };
        targets = [{
          expr = ''{host="weka", level=~"emerg|alert|crit|err"}'';
          refId = "A";
          datasource = { type = "loki"; uid = "loki"; };
        }];
        options = { showTime = true; wrapLogMessage = true; sortOrder = "Descending"; };
      }
    ];
  };

  dashboards = pkgs.linkFarm "grafana-dashboards" [
    { name = "weka.json"; path = pkgs.writeText "weka.json" (builtins.toJSON weka); }
  ];

  secret = {
    owner = "grafana";
    restartUnits = [ "grafana.service" ];
  };
in
{
  sops.secrets.grafana_secret_key = secret;
  sops.secrets.grafana_admin_password = secret;

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = port;
        inherit domain;
        root_url = "https://${domain}/";
      };
      # Log in from the identity tailscale serve puts on each request, so no
      # password prompt. Safe because Grafana only listens on localhost, where
      # the only client is tailscale serve, and it overwrites these headers.
      # Requests without the header (tagged devices) fall back to the login
      # form. New tailnet users are created as Viewers.
      # @see: https://tailscale.com/kb/1312/serve#identity-headers
      # @see: https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/auth-proxy/
      "auth.proxy" = {
        enabled = true;
        header_name = "Tailscale-User-Login";
        header_property = "username";
        headers = "Name:Tailscale-User-Name";
        auto_sign_up = true;
        whitelist = "127.0.0.1, ::1";
      };
      security = {
        # Matches the Tailscale login so the header lands on the admin account.
        # Only used when the database is first created (the existing account
        # was renamed from "jack" to match).
        admin_user = "jay-aye-see-kay@github";
        admin_password = "$__file{${config.sops.secrets.grafana_admin_password.path}}";
        secret_key = "$__file{${config.sops.secrets.grafana_secret_key.path}}";
        cookie_secure = true;
      };
      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
        check_for_plugin_updates = false;
      };
      news.news_feed_enabled = false;
      # Open straight onto the weka dashboard
      dashboards.default_home_dashboard_path = "${dashboards}/weka.json";
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [{
        name = "Prometheus";
        type = "prometheus";
        uid = "prometheus";
        url = "http://127.0.0.1:${toString config.services.prometheus.port}";
        isDefault = true;
      }];
      dashboards.settings.providers = [{
        name = "nixfiles";
        disableDeletion = true;
        allowUiUpdates = false;
        options.path = dashboards;
      }];
    };
  };

  weka.tailscaleServices.grafana = port;
}
