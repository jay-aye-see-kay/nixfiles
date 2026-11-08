# Home Assistant as the official container (podman), with Mosquitto as a native
# service. Tailnet: https://home-assistant.tarpan-krait.ts.net (a Tailscale
# Service). LAN: http://192.168.10.101:8123, the address the old HAOS VM had,
# so MQTT devices, the mobile apps and the Reolink webhook don't change.
#
# Config lives in /var/lib/hass (dataset rpool/crypt/data/hass), edited in the
# UI. sanoid and restic cover it like every other dataset. configuration.yaml
# needs `http: { use_x_forwarded_for: true, trusted_proxies: [127.0.0.1, ::1] }`
# or HA answers Tailscale Serve with a 400.
#
# Upgrades: bump `tag`. The image only changes when the tag does. If an upgrade
# migrates the recorder DB, roll back the DB from a ZFS snapshot too.
# @see: https://wiki.nixos.org/wiki/Home_Assistant#OCI_container
# @see: home-server/HOME-ASSISTANT.md in dumpbox
{ config, lib, ... }:
let
  port = 8123;
  # Same version as the HAOS VM, so the restored data isn't migrated at cutover
  tag = "2026.10.4";

  # Until cutover the VM on pm1 still owns .101 and the ZBT-1. Flip this when
  # moving: it adds the address, passes the stick through and starts HA on boot.
  cutover = false;
  serviceAddress = "192.168.10.101";
  # The ZBT-1 on the host, and the path ZHA stored in .storage/core.config_entries
  # (fill both in from pm1 before cutover)
  zbt1 = "/dev/serial/by-id/usb-Nabu_Casa_Home_Assistant_Connect_ZBT-1_TODO-if00-port0";
  zhaPath = zbt1;
in
{
  virtualisation.oci-containers = {
    backend = "podman";
    containers.homeassistant = {
      image = "ghcr.io/home-assistant/home-assistant:${tag}";
      # Before cutover: `systemctl start podman-homeassistant` to try it out
      autoStart = cutover;
      volumes = [ "/var/lib/hass:/config" ];
      environment.TZ = config.time.timeZone;
      extraOptions = [
        # mDNS, HomeKit Bridge and Apple TV discovery need the host network
        "--network=host"
      ] ++ lib.optional cutover "--device=${zbt1}:${zhaPath}";
    };
  };

  # Users have no topic access unless given an ACL. The `mqtt` user keeps the
  # password the devices (Tasmota, Faikin, Valetudo) already have.
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

  networking.interfaces.enp34s0.ipv4.addresses = lib.mkIf cutover [
    { address = serviceAddress; prefixLength = 24; }
  ];

  networking.firewall.interfaces.enp34s0 = {
    # HA, MQTT, HomeKit Bridge
    allowedTCPPorts = [ port 1883 21064 ];
    # mDNS
    allowedUDPPorts = [ 5353 ];
  };

  weka.tailscaleServices.home-assistant = port;

  # HA's own backups would just be a second copy of what restic already has
  services.restic.backups.weka.exclude = [ "/var/lib/hass/.zfs/snapshot/restic/backups" ];
}
