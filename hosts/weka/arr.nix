# Prowlarr, Sonarr, Radarr and Lidarr, confined to a WireGuard network
# namespace (Mullvad), so nothing they send to indexers or metadata APIs
# leaves from the home IP. Web UIs are Tailscale Services as usual
# (https://<app>.tarpan-krait.ts.net), proxied to the namespace's address.
#
# The namespace has lo, the tunnel (vpn0), and a veth to a bridge on the
# host. Its only default route is the tunnel, and VPN-Confinement drops new
# outgoing connections on the veth, so if the tunnel is down the apps have
# no way out at all (fails closed, no kill-switch rules needed). Inbound on
# vpn0 is dropped too, so binding to * inside the namespace is fine.
#
# portMappings DNATs the ports on every host interface, not just from
# localhost. That's still only reachable from weka itself: the namespace
# routes replies for anything outside 192.168.15.0/24 into the tunnel, so a
# LAN or tailnet client never gets an answer. Keep allowedIngress empty, or
# the apps (which have no login, see auth below) become reachable from there.
#
# State is one dataset per app under rpool/crypt/data (see disko.nix). The
# app config that matters (indexers, profiles, download clients) lives in
# each app's SQLite database and is set up in the UI.
#
# The library (tank1, /srv/media) predates this and is all root:root 755.
# Hand it to the media group once, on weka:
#   sudo mkdir -p /srv/media/music
#   sudo chgrp -R media /srv/media/tv /srv/media/movies /srv/media/music
#   sudo chmod -R g+w /srv/media/tv /srv/media/movies /srv/media/music
#   sudo find /srv/media/tv /srv/media/movies /srv/media/music -type d -exec chmod g+s {} +
# Not tmpfiles: /srv/media is nofail, so tmpfiles could run before tank1 is
# mounted and create the directories on rpool underneath it.
# @see: https://github.com/Maroka-chan/VPN-Confinement
# @see: https://wiki.servarr.com/useful-tools#using-environment-variables-for-config
{ config, lib, ... }:
let
  ns = config.vpnNamespaces.vpn;

  # Port of each app. Names match the sops keys (<app>_api_key) and the
  # Tailscale Services.
  apps = {
    prowlarr = 9696;
    sonarr = 8989;
    radarr = 7878;
    lidarr = 8686;
  };
  # Apps that write to the library, and the one folder of it each may write.
  # Root folders set in an app's UI have to be inside its folder.
  mediaApps = {
    sonarr = "/srv/media/tv";
    radarr = "/srv/media/movies";
    lidarr = "/srv/media/music";
  };

  # nixpkgs hardens sonarr and radarr but not lidarr or prowlarr. This is
  # sonarr's set, at mkDefault so a module's own value wins wherever it sets
  # one (and lists like SystemCallFilter aren't merged into duplicates).
  # Not MemoryDenyWriteExecute: .NET's JIT needs W+X memory.
  hardening = lib.mapAttrs (_: lib.mkDefault) {
    CapabilityBoundingSet = "";
    NoNewPrivileges = true;
    ProtectHome = true;
    ProtectClock = true;
    ProtectKernelLogs = true;
    PrivateTmp = true;
    PrivateDevices = true;
    PrivateUsers = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    RestrictSUIDSGID = true;
    RemoveIPC = true;
    ProtectHostname = true;
    ProtectProc = "invisible";
    RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    LockPersonality = true;
    SystemCallArchitectures = "native";
    SystemCallFilter = [ "@system-service" "~@privileged" "~@debug" "~@mount" "@chown" ];
    # Not in any of the modules: without it each app can write anywhere its
    # user can and read anything world-readable on weka.
    ProtectSystem = "strict";
  };

  perApp = f: lib.mkMerge (lib.mapAttrsToList f apps);
in
{
  sops.secrets = {
    # Mullvad's wg-quick config (account page → WireGuard configuration).
    # Root-only, read by the namespace's setup script.
    mullvad_wg_conf.restartUnits = [ "vpn.service" ];
  } // lib.mapAttrs' (app: _: lib.nameValuePair "${app}_api_key" { }) apps;

  # API keys from sops instead of generated on first start, so they survive
  # a reinstall and Homepage can use them (homepage.nix). The *arrs read
  # <APP>__AUTH__APIKEY over the value in config.xml.
  sops.templates = lib.mapAttrs'
    (app: _: lib.nameValuePair "${app}.env" {
      content = "${lib.toUpper app}__AUTH__APIKEY=${config.sops.placeholder."${app}_api_key"}";
      restartUnits = [ "${app}.service" ];
    })
    apps;

  # Name max 7 characters. Generic rather than "mullvad", for when the
  # provider changes. Interface vpn0, bridge vpn-br, address 192.168.15.1.
  vpnNamespaces.vpn = {
    enable = true;
    wireguardConfigFile = config.sops.secrets.mullvad_wg_conf.path;
    portMappings = lib.attrValues apps;
  };

  # Shared group for the library, so the apps (and later the download
  # client) can all write to it. Jellyfin only reads, which the mode allows.
  users.groups.media = { };

  services = perApp (app: port: {
    ${app} = {
      enable = true;
      environmentFiles = [ config.sops.templates."${app}.env".path ];
      settings = {
        server.port = port;
        # No login: Tailscale is the access control, as for every other app
        # here. External means "a proxy in front handles auth".
        auth.method = "External";
      };
    } // lib.optionalAttrs (mediaApps ? ${app}) { group = "media"; };
  });

  systemd.services = perApp (app: _: {
    ${app} = lib.mkMerge [
      {
        vpnConfinement = {
          enable = true;
          vpnNamespace = "vpn";
        };
        # bindsTo (from VPN-Confinement) stops the app when the namespace
        # goes, but wouldn't start it again. partOf passes restarts through
        # too, e.g. when the WireGuard config changes.
        partOf = [ "vpn.service" ];
        serviceConfig = hardening;
      }
      # Data dir writable under ProtectSystem. Sonarr and prowlarr get theirs
      # from StateDirectory; these two create it with tmpfiles instead.
      (lib.mkIf (lib.elem app [ "radarr" "lidarr" ]) {
        serviceConfig.ReadWritePaths = [ "/var/lib/${app}" ];
      })
      (lib.mkIf (mediaApps ? ${app}) {
        # The app's own library folder only. It must exist (see the setup
        # steps at the top), or the unit fails to start with 226/NAMESPACE.
        # The download client's folder will need adding here too, for
        # imports and hardlinks.
        serviceConfig.ReadWritePaths = [ mediaApps.${app} ];
        # Group-writable files in the library, so hardlinks and moves work
        # between apps (fs.protected_hardlinks wants write access to the file)
        serviceConfig.UMask = lib.mkForce "0002";
        # /srv/media is nofail (tank1.nix): stay down without it, rather than
        # report every series and film as missing.
        unitConfig.RequiresMountsFor = [ "/srv/media" ];
      })
    ];
  });

  weka.tailscaleServices = lib.mapAttrs
    (_: port: { host = ns.namespaceAddress; inherit port; })
    apps;
}
