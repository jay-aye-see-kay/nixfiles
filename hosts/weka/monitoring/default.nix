# Metrics, alerts, dashboards and logs. See "Monitoring" in README.md.
{
  imports = [
    ./prometheus.nix
    ./grafana.nix
    ./logs.nix
  ];
}
