# UPS: Tripp Lite OMNIVSX1500A on USB. `upsc tripplite` shows what it reports.
# Shuts weka down at 50% charge, about 30 minutes on battery.
# @see: https://networkupstools.org/docs/man/ups.conf.html
{ config, pkgs, ... }:
let
  passwordFile = "/var/lib/nut/upsmon.password";
in
{
  power.ups = {
    enable = true;
    mode = "standalone";

    ups.tripplite = {
      driver = "usbhid-ups";
      port = "auto";
      description = "Tripp Lite OMNIVSX1500A";
      directives = [
        "vendorid = 09ae"
        # The unit doesn't report when its own low-battery flag fires, so
        # raise it ourselves at 50%, leaving margin for an ageing battery
        "ignorelb"
        "override.battery.charge.low = 50"
      ];
    };

    users.upsmon = {
      inherit passwordFile;
      upsmon = "primary";
    };

    # primary: after shutdown, tell the UPS to cut its outlets and restore
    # them when mains returns, so weka can boot again
    upsmon.monitor.tripplite = {
      user = "upsmon";
      type = "primary";
    };
  };

  # upsd is localhost only, so a generated password kept out of the store is enough
  systemd.services.upsmon-password = {
    description = "Generate the local upsd password for upsmon";
    before = [ "upsd.service" "upsmon.service" ];
    requiredBy = [ "upsd.service" "upsmon.service" ];
    unitConfig.ConditionPathExists = "!${passwordFile}";
    serviceConfig = {
      Type = "oneshot";
      UMask = "0077";
    };
    script = ''
      mkdir -p /var/lib/nut
      ${pkgs.openssl}/bin/openssl rand -hex 32 > ${passwordFile}
    '';
  };

  # For Prometheus (monitoring/prometheus.nix). Its default variable list
  # skips runtime. ups.load is left out: this unit always reports 0.
  services.prometheus.exporters.nut = {
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
  services.prometheus.scrapeConfigs = [{
    job_name = "nut";
    metrics_path = "/ups_metrics";
    static_configs = [{ targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.nut.port}" ]; }];
  }];
}
