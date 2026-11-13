# Monitoring: Prometheus scrapes node_exporter, alert rules fire into
# Alertmanager, which posts to Slack (#weka-alerts). An always-firing Watchdog
# alert pings Healthchecks.io every couple of minutes, so if weka, Prometheus
# or Alertmanager stops, Healthchecks.io notices the silence and tells Slack.
#
# Nothing pages: alerts wait until someone looks. One message per problem, a
# daily reminder while it lasts, and a "resolved" message when it clears.
#
# UIs over Tailscale: https://prometheus.tarpan-krait.ts.net (queries, alert
# state) and https://alertmanager.tarpan-krait.ts.net (silences).
# Outside setup (Slack app, Healthchecks.io check) is in README.md.
{ config, lib, pkgs, ... }:
let
  # Needs the Healthchecks.io ping URL in sops. When false, the Watchdog goes
  # to a receiver that sends nothing.
  healthchecks = true;
  textfileDir = "/var/lib/prometheus-node-exporter-text";
  tailnet = "tarpan-krait.ts.net";
  promPort = config.services.prometheus.port;
  amPort = config.services.prometheus.alertmanager.port;
  nodePort = config.services.prometheus.exporters.node.port;
  smartPort = config.services.prometheus.exporters.smartctl.port;
  nutPort = config.services.prometheus.exporters.nut.port;

  # Write a .prom file atomically, so node_exporter never reads half of one
  writeProm = name: ''
    {
      tmp=$(mktemp ${textfileDir}/.${name}.XXXXXX)
      cat > "$tmp"
      chmod 644 "$tmp"
      mv "$tmp" ${textfileDir}/${name}.prom
    }
  '';

  zfsMetrics = pkgs.writeShellApplication {
    name = "zfs-metrics";
    runtimeInputs = [ config.boot.zfs.package pkgs.jq pkgs.coreutils ];
    text = ''
      {
        echo "# zfs_pool_online 1 if the pool state is ONLINE."
        echo "# zfs_pool_errors Read/write/checksum errors summed over all vdevs, and data errors."
        echo "# zfs_pool_used_ratio Allocated space over pool size."
        echo "# zfs_pool_last_scrub_timestamp_seconds When the last scrub finished."
        zpool status -jp --json-int | jq -r '
          .pools[] | .name as $p |
          "zfs_pool_online{pool=\"\($p)\"} \(if .state == "ONLINE" then 1 else 0 end)",
          ([.vdevs | .. | objects | select(has("read_errors"))] as $v |
            "zfs_pool_errors{pool=\"\($p)\",type=\"read\"} \([$v[].read_errors] | add // 0)",
            "zfs_pool_errors{pool=\"\($p)\",type=\"write\"} \([$v[].write_errors] | add // 0)",
            "zfs_pool_errors{pool=\"\($p)\",type=\"checksum\"} \([$v[].checksum_errors] | add // 0)"),
          "zfs_pool_errors{pool=\"\($p)\",type=\"data\"} \(.error_count // 0)",
          (.vdevs[$p] | "zfs_pool_used_ratio{pool=\"\($p)\"} \(.alloc_space / .total_space)"),
          (.scan_stats // {} | select(.function == "SCRUB" and .state == "FINISHED") |
            "zfs_pool_last_scrub_timestamp_seconds{pool=\"\($p)\"} \(.end_time)")'

        # Newest snapshot per app dataset, tank1/media and each syncoid copy
        # (0 if it has none). tank1 is allowed to be missing.
        echo "# zfs_newest_snapshot_timestamp_seconds Creation time of the dataset's newest snapshot."
        { zfs list -Hp -o name -r -d 1 rpool/crypt/data | tail -n +2
          zfs list -Hp -o name tank1/media 2>/dev/null || true
          zfs list -Hp -o name -r -d 1 tank1/backup/weka 2>/dev/null | tail -n +2 || true
        } | while read -r ds; do
          newest=$(zfs list -Hp -t snapshot -o creation -s creation -d 1 "$ds" | tail -n 1)
          echo "zfs_newest_snapshot_timestamp_seconds{dataset=\"$ds\"} ''${newest:-0}"
        done
      } | ${writeProm "zfs"}
    '';
  };

  rules = [{
    name = "weka";
    rules = [
      {
        # Always firing. Routed to Healthchecks.io, never to Slack.
        alert = "Watchdog";
        expr = "vector(1)";
        annotations.summary = "Alerting pipeline heartbeat";
      }
      {
        alert = "TargetDown";
        expr = "up == 0";
        for = "5m";
        annotations.summary = "{{ $labels.job }} isn't being scraped";
      }
      {
        alert = "SystemdUnitFailed";
        expr = ''node_systemd_unit_state{state="failed"} == 1'';
        annotations.summary = "{{ $labels.name }} failed";
        annotations.description = "journalctl -u {{ $labels.name }}";
      }
      {
        alert = "ZfsPoolNotOnline";
        expr = "zfs_pool_online == 0";
        annotations.summary = "Pool {{ $labels.pool }} isn't ONLINE";
        annotations.description = "zpool status {{ $labels.pool }}";
      }
      {
        alert = "ZfsPoolErrors";
        expr = "zfs_pool_errors > 0";
        annotations.summary = "Pool {{ $labels.pool }} has {{ $value }} {{ $labels.type }} errors";
        annotations.description = "zpool status -v {{ $labels.pool }}";
      }
      {
        alert = "ZfsScrubOverdue";
        expr = "time() - zfs_pool_last_scrub_timestamp_seconds > 35 * 86400";
        annotations.summary = "Pool {{ $labels.pool }} hasn't been scrubbed in over 5 weeks";
      }
      {
        alert = "ZfsPoolFilling";
        expr = "zfs_pool_used_ratio > 0.85";
        annotations.summary = "Pool {{ $labels.pool }} is {{ $value | humanizePercentage }} full";
      }
      {
        # Non-ZFS filesystems (the ESP). ZFS datasets are covered by the pool.
        alert = "FilesystemFilling";
        expr = ''
          1 - node_filesystem_avail_bytes{fstype!~"zfs|tmpfs|ramfs"}
            / node_filesystem_size_bytes{fstype!~"zfs|tmpfs|ramfs"} > 0.85
        '';
        annotations.summary = "{{ $labels.mountpoint }} is {{ $value | humanizePercentage }} full";
      }
      {
        # sanoid snapshots rpool hourly, so this means it has stopped
        alert = "ZfsSnapshotsStale";
        expr = ''time() - zfs_newest_snapshot_timestamp_seconds{dataset=~"rpool/.*"} > 6 * 3600'';
        annotations.summary = "{{ $labels.dataset }} has no snapshot in the last 6 hours";
        annotations.description = "systemctl status sanoid";
      }
      {
        # tank1/media is snapshotted daily, and the syncoid copies arrive daily
        alert = "ZfsTank1SnapshotsStale";
        expr = ''time() - zfs_newest_snapshot_timestamp_seconds{dataset=~"tank1/.*"} > 2 * 86400'';
        annotations.summary = "{{ $labels.dataset }} has no snapshot in the last 2 days";
        annotations.description = "systemctl status sanoid syncoid-rpool-crypt-data";
      }
      {
        alert = "ResticBackupStale";
        expr = "time() - restic_last_success_timestamp_seconds > 36 * 3600";
        annotations.summary = "No successful restic backup in 36 hours";
        annotations.description = "journalctl -u restic-backups-weka";
      }
      {
        alert = "SmartFailing";
        expr = "smartctl_device_smart_status == 0";
        annotations.summary = "{{ $labels.device }} fails its SMART health check";
        annotations.description = "smartctl -a /dev/{{ $labels.device }}";
      }
      {
        alert = "NvmeCriticalWarning";
        expr = "smartctl_device_critical_warning > 0";
        annotations.summary = "{{ $labels.device }} reports an NVMe critical warning";
        annotations.description = "smartctl -a /dev/{{ $labels.device }}";
      }
      {
        alert = "NvmeWearing";
        expr = "smartctl_device_percentage_used > 80";
        annotations.summary = "{{ $labels.device }} has used {{ $value }}% of its rated endurance";
      }
      {
        alert = "NvmeSpareLow";
        expr = "smartctl_device_available_spare < smartctl_device_available_spare_threshold * 2";
        annotations.summary = "{{ $labels.device }} is running out of spare blocks";
      }
      {
        alert = "DiskMediaErrors";
        expr = "increase(smartctl_device_media_errors[1d]) > 0";
        annotations.summary = "{{ $labels.device }} logged new media errors today";
        annotations.description = "smartctl -a /dev/{{ $labels.device }}";
      }
      {
        # HDDs (tank1): sectors being remapped or waiting to be
        alert = "DiskSectorsGrowing";
        expr = ''
          increase(smartctl_device_attribute{attribute_name=~"Reallocated_Sector_Ct|Current_Pending_Sector|Offline_Uncorrectable",attribute_value_type="raw"}[1d]) > 0
        '';
        annotations.summary = "{{ $labels.device }}: {{ $labels.attribute_name }} went up today";
        annotations.description = "smartctl -a /dev/{{ $labels.device }}";
      }
      {
        # The 970 EVO starts throttling around 70°C, and it can get there.
        alert = "NvmeHot";
        expr = ''smartctl_device_temperature{device=~"nvme.*",temperature_type="current"} > 65'';
        for = "10m";
        annotations.summary = "{{ $labels.device }} is at {{ $value }}°C";
      }
      {
        # tank1's WD Reds are rated to 65°C, but above 45°C wears them faster.
        alert = "DiskHot";
        expr = ''smartctl_device_temperature{device!~"nvme.*",temperature_type="current"} > 45'';
        for = "15m";
        annotations.summary = "{{ $labels.device }} is at {{ $value }}°C";
      }
      {
        # Tctl from k10temp, matched by driver name since the chip label is a PCI path
        alert = "CpuHot";
        expr = ''
          node_hwmon_temp_celsius * on(chip) group_left(chip_name)
            node_hwmon_chip_names{chip_name="k10temp"} > 80
        '';
        for = "10m";
        annotations.summary = "CPU is at {{ $value | printf \"%.0f\" }}°C";
      }
      {
        # fan1 and fan2 are the only connected headers; they idle at ~800-950 RPM
        alert = "FanStopped";
        expr = ''node_hwmon_fan_rpm{chip=~"platform_nct6775_.*",sensor=~"fan[12]"} < 200'';
        for = "5m";
        annotations.summary = "{{ $labels.sensor }} is at {{ $value }} RPM";
      }
      {
        # The root pool needed its passphrase instead of unlocking from Tang.
        # Only for a day after the boot, since the metric holds until the next.
        alert = "RootUnlockedManually";
        expr = "boot_unlocked_by_clevis == 0 and time() - node_boot_time_seconds < 86400";
        annotations.summary = "weka's root pool didn't unlock itself at boot";
        annotations.description = "journalctl -b -u zfs-import-rpool; is tang.jackrose.co.nz/weka/adv up?";
      }
      {
        # A metric that should exist has gone missing, e.g. a script broke
        alert = "TextfileMetricsMissing";
        expr = ''
          absent(zfs_pool_online) or absent(restic_last_success_timestamp_seconds)
            or absent(boot_unlocked_by_clevis)
            or time() - node_textfile_mtime_seconds{file=~".*zfs.prom"} > 1800
        '';
        for = "1h";
        annotations.summary = "ZFS, restic or unlock metrics are missing or stale";
      }
    ];
  }];
in
{
  sops.secrets.alertmanager_slack_webhook = { };
  sops.secrets.healthchecks_watchdog_url = lib.mkIf healthchecks { };

  # Driver for the board's Nuvoton NCT6793D Super I/O chip: fan RPM, fan PWM
  # and motherboard temperatures. Not auto-loaded, and hardware.nix is
  # generated, so it lives here with the exporter that reads it.
  boot.kernelModules = [ "nct6775" ];

  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    webExternalUrl = "https://prometheus.${tailnet}";
    retentionTime = "2y";
    globalConfig = {
      scrape_interval = "30s";
      evaluation_interval = "30s";
    };
    scrapeConfigs = [
      { job_name = "prometheus"; static_configs = [{ targets = [ "127.0.0.1:${toString promPort}" ]; }]; }
      { job_name = "alertmanager"; static_configs = [{ targets = [ "127.0.0.1:${toString amPort}" ]; }]; }
      { job_name = "node"; static_configs = [{ targets = [ "127.0.0.1:${toString nodePort}" ]; }]; }
      { job_name = "smartctl"; static_configs = [{ targets = [ "127.0.0.1:${toString smartPort}" ]; }]; }
      {
        job_name = "nut";
        metrics_path = "/ups_metrics";
        static_configs = [{ targets = [ "127.0.0.1:${toString nutPort}" ]; }];
      }
    ];
    ruleFiles = [ (pkgs.writeText "weka-rules.yml" (builtins.toJSON { groups = rules; })) ];
    alertmanagers = [{ static_configs = [{ targets = [ "127.0.0.1:${toString amPort}" ]; }]; }];

    exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
      enabledCollectors = [ "systemd" ];
      extraFlags = [
        "--collector.textfile.directory=${textfileDir}"
        # Drop the NCT6793D inputs with nothing wired to them: SYSTIN and
        # AUXTIN1-3 read 110-118°C, TSI2-7 are garbage, PCH/DIMM read 0, and
        # TSI0 duplicates the CPU. Keeps temp2 (CPUTIN), temp3 (AUXTIN0, drives
        # fan1's curve) and temp7 (CPU via SB-TSI, drives fan2's curve).
        "--collector.hwmon.sensor-exclude=platform_nct6775_.*;temp(1|[4-689]|1[0-9]|20)"
      ];
    };

    # SMART for every drive smartctl finds (the NVMe and tank1's HDDs).
    # NVMe access comes from a udev rule that only runs when the device is
    # added, so if the exporter is ever newly enabled it needs
    # `udevadm trigger --subsystem-match=nvme --action=add` and an exporter
    # restart (or a reboot).
    exporters.smartctl = {
      enable = true;
      listenAddress = "127.0.0.1";
    };

    # UPS, from upsd (see ups.nix). Its default variable list skips runtime.
    # ups.load is left out: this unit always reports 0.
    exporters.nut = {
      enable = true;
      listenAddress = "127.0.0.1";
      nutVariables = [
        "battery.charge"
        "battery.charge.low"
        "battery.runtime"
        "battery.voltage"
        "input.voltage"
        "output.voltage"
        "ups.status"
      ];
    };

    alertmanager = {
      enable = true;
      listenAddress = "127.0.0.1";
      webExternalUrl = "https://alertmanager.${tailnet}";
      configuration = {
        route = {
          receiver = "slack";
          group_by = [ "alertname" ];
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "24h";
          routes = [{
            matchers = [ ''alertname="Watchdog"'' ];
            receiver = "healthchecks";
            group_wait = "0s";
            group_interval = "1m";
            repeat_interval = "2m";
          }];
        };
        receivers = [
          {
            name = "slack";
            slack_configs = [{
              # Alertmanager is a DynamicUser, so the secret comes in as a
              # systemd credential rather than straight from /run/secrets
              api_url_file = "/run/credentials/alertmanager.service/slack_webhook";
              send_resolved = true;
              title = ''{{ if eq .Status "firing" }}🔴{{ else }}✅{{ end }} {{ .CommonLabels.alertname }}'';
              text = "{{ range .Alerts }}• {{ .Annotations.summary }}{{ if .Annotations.description }} (`{{ .Annotations.description }}`){{ end }}\n{{ end }}";
            }];
          }
          ({ name = "healthchecks"; } // lib.optionalAttrs healthchecks {
            webhook_configs = [{
              url_file = "/run/credentials/alertmanager.service/healthchecks_url";
              send_resolved = false;
            }];
          })
        ];
      };
    };
  };

  systemd.services.alertmanager.serviceConfig.LoadCredential = [
    "slack_webhook:${config.sops.secrets.alertmanager_slack_webhook.path}"
  ] ++ lib.optional healthchecks
    "healthchecks_url:${config.sops.secrets.healthchecks_watchdog_url.path}";

  systemd.tmpfiles.rules = [ "d ${textfileDir} 0755 root root -" ];

  systemd.services.zfs-metrics = {
    description = "ZFS pool and snapshot metrics for node_exporter";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe zfsMetrics;
    };
    startAt = "*:0/5";
  };

  # How this boot's root pool unlocked: the initrd's clevis wrapper (see
  # clevisMarked in default.nix) leaves /run/clevis-unlocked on success.
  systemd.services.unlock-metrics = {
    description = "Root pool unlock method for node_exporter";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-tmpfiles-setup.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      unlocked=0
      [ -e /run/clevis-unlocked ] && unlocked=1
      {
        echo "# boot_unlocked_by_clevis 1 if the root pool unlocked from Tang this boot, 0 if by passphrase."
        echo "boot_unlocked_by_clevis $unlocked"
      } | ${writeProm "unlock"}
    '';
  };

  # Only after the backup, prune and check have all succeeded
  systemd.services.restic-backups-weka.serviceConfig.ExecStartPost =
    pkgs.writeShellScript "restic-metrics" ''
      echo "restic_last_success_timestamp_seconds $(${pkgs.coreutils}/bin/date +%s)" | ${writeProm "restic"}
    '';

  weka.tailscaleServices = {
    prometheus = promPort;
    alertmanager = amPort;
  };

  services.journald.extraConfig = "SystemMaxUse=4G";
}
