# Logs: Alloy reads the systemd journal and pushes it to Loki, which Grafana
# queries next to the metrics (Explore → Loki, e.g. {unit="mealie.service"}).
# journald keeps its own copy too (capped at 4G in monitoring.nix), so
# journalctl still works if this is broken.
#
# Loki keeps 90 days, on rpool/crypt/nosnap/loki: not snapshotted or backed
# up, since losing log history is accepted.
# @see: home-server/MONITORING.md in dumpbox
# @see: https://grafana.com/docs/loki/latest/configure/
{ config, ... }:
let
  lokiPort = 3100;
  alloyPort = 12345;
  dataDir = config.services.loki.dataDir;
in
{
  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_address = "127.0.0.1";
        http_listen_port = lokiPort;
        grpc_listen_address = "127.0.0.1";
        grpc_listen_port = 9096;
      };
      common = {
        path_prefix = dataDir;
        replication_factor = 1;
        instance_addr = "127.0.0.1";
        ring.kvstore.store = "inmemory";
        storage.filesystem = {
          chunks_directory = "${dataDir}/chunks";
          rules_directory = "${dataDir}/rules";
        };
      };
      schema_config.configs = [{
        from = "2026-11-01";
        store = "tsdb";
        object_store = "filesystem";
        schema = "v13";
        index = { prefix = "index_"; period = "24h"; };
      }];
      # Without retention on in the compactor, Loki keeps logs forever
      limits_config.retention_period = "90d";
      compactor = {
        working_directory = "${dataDir}/compactor";
        retention_enabled = true;
        delete_request_store = "filesystem";
      };
      analytics.reporting_enabled = false;
    };
  };

  # The Loki module doesn't create its data dir, and the dataset mounts over
  # it owned by root, so set the owner here (tmpfiles runs after mounts)
  systemd.tmpfiles.rules = [ "d ${dataDir} 0700 loki loki -" ];
  systemd.services.loki.unitConfig.RequiresMountsFor = [ dataDir ];

  services.alloy = {
    enable = true;
    extraFlags = [
      "--server.http.listen-addr=127.0.0.1:${toString alloyPort}"
      "--disable-reporting"
    ];
  };

  environment.etc."alloy/config.alloy".text = ''
    loki.relabel "journal" {
      forward_to = []
      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        target_label  = "level"
      }
      rule {
        source_labels = ["__journal_syslog_identifier"]
        target_label  = "identifier"
      }
    }

    loki.source.journal "journal" {
      forward_to    = [loki.write.local.receiver]
      relabel_rules = loki.relabel.journal.rules
      labels        = { host = "weka" }
      max_age       = "12h"
    }

    loki.write "local" {
      endpoint {
        url = "http://127.0.0.1:${toString lokiPort}/loki/api/v1/push"
      }
    }
  '';

  services.prometheus.scrapeConfigs = [
    { job_name = "loki"; static_configs = [{ targets = [ "127.0.0.1:${toString lokiPort}" ]; }]; }
    { job_name = "alloy"; static_configs = [{ targets = [ "127.0.0.1:${toString alloyPort}" ]; }]; }
  ];

  services.grafana.provision.datasources.settings.datasources = [{
    name = "Loki";
    type = "loki";
    uid = "loki";
    url = "http://127.0.0.1:${toString lokiPort}";
  }];
}
