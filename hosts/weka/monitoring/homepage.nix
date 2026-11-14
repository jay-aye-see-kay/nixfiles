# Homepage cards for Grafana, Prometheus and Alertmanager: the health of
# backups, pools and alerts at a glance, from Prometheus queries.
# @see: https://gethomepage.dev/widgets/services/prometheusmetric/
{ config, ... }:
let
  promUrl = "http://127.0.0.1:${toString config.services.prometheus.port}";

  promMetric = label: query: format: { inherit label query format; };
  # One row of up to 4 Prometheus queries; a card can stack several
  promRow = metrics: { type = "prometheusmetric"; url = promUrl; refreshInterval = 60000; inherit metrics; };
  ago = { type = "relativeDate"; scale = 1000; };
in
{
  weka.homepage = {
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
}
