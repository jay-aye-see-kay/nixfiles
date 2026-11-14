# Home Assistant as the official container (podman), with Mosquitto as a native
# service. Tailnet: https://home-assistant.tarpan-krait.ts.net (a Tailscale
# Service). LAN: http://192.168.10.101:8123, the address MQTT devices, the
# mobile apps and the Reolink webhook use. It's weka's only LAN address, from
# a fixed DHCP lease in UniFi (by MAC), so the initrd unlock is at .101 too.
# HA uses the host network and Mosquitto listens on every address, so nothing
# here binds to it.
#
# Config lives in /var/lib/hass (dataset rpool/crypt/data/hass), edited in the
# UI. sanoid and restic cover it like every other dataset. HA answers Tailscale
# Serve with a 400 unless it has use_x_forwarded_for and trusted_proxies
# [127.0.0.1, ::1], which live in .storage/http, not YAML (see README.md).
#
# Upgrades: bump `tag`. The image only changes when the tag does. If an upgrade
# migrates the recorder DB, roll back the DB from a ZFS snapshot too.
# @see: https://wiki.nixos.org/wiki/Home_Assistant#OCI_container
{ config, ... }:
let
  port = 8123;
  tag = "2026.10.4";
  # The Zigbee stick (ZBT-1). ZHA stores this by-id path, so it's passed into
  # the container at the same path.
  zbt1 = "/dev/serial/by-id/usb-Nabu_Casa_Home_Assistant_Connect_ZBT-1_20d1413b0339ef11ab18ead154516304-if00-port0";
in
{
  virtualisation.oci-containers = {
    backend = "podman";
    containers.homeassistant = {
      image = "ghcr.io/home-assistant/home-assistant:${tag}";
      volumes = [ "/var/lib/hass:/config" ];
      environment.TZ = config.time.timeZone;
      extraOptions = [
        # mDNS, HomeKit Bridge and Apple TV discovery need the host network
        "--network=host"
        "--device=${zbt1}:${zbt1}"
        # Also as the kernel name: HA's USB scan reads sysfs, finds ttyUSB0 and
        # rewrites the ZBT-1 hardware entry to that path ("device not plugged in"
        # otherwise). The host side stays by-id, so it's always this stick.
        "--device=${zbt1}:/dev/ttyUSB0"
        # Run the container inside the service's own cgroup (what Quadlet
        # does), not a separate libpod scope in machine.slice. At shutdown
        # systemd would stop that scope directly, SIGTERMing every process in
        # the container at once, and HA dies before the recorder closes its DB.
        # This overrides the module's --cgroups=enabled (the last flag wins).
        "--cgroups=split"
        # podman's default is 10s, then SIGKILL, and HA can need longer.
        # systemd's TimeoutStopSec is 120s, so this still fits inside it.
        "--stop-timeout=60"
      ];
    };
  };

  # Users have no topic access unless given an ACL. `mqtt` is the login the
  # devices (Tasmota, Faikin, Valetudo) use, `homeassistant` is HA's own.
  services.mosquitto = {
    enable = true;
    listeners = [{
      port = 1883;
      users = {
        mqtt = {
          acl = [ "readwrite #" ];
          passwordFile = config.sops.secrets.mqtt_password_mqtt.path;
        };
        homeassistant = {
          acl = [ "readwrite #" ];
          passwordFile = config.sops.secrets.mqtt_password_homeassistant.path;
        };
      };
    }];
  };

  # Read by mosquitto through LoadCredential, so root-owned is fine
  sops.secrets.mqtt_password_mqtt = { };
  sops.secrets.mqtt_password_homeassistant = { };

  networking.firewall.interfaces.lan0 = {
    # HA, MQTT, HomeKit Bridge
    allowedTCPPorts = [ port 1883 21064 ];
    # mDNS
    allowedUDPPorts = [ 5353 ];
  };

  weka.tailscaleServices.home-assistant = port;

  # HA's own backups would just be a second copy of what restic already has
  services.restic.backups.weka.exclude = [ "/var/lib/hass/.zfs/snapshot/restic/backups" ];
}
