# Prowlarr, Sonarr, Radarr, Lidarr, qBittorrent (with the VueTorrent web
# UI) and FlareSolverr, confined to a WireGuard network namespace (Mullvad), so nothing they
# send to indexers, metadata APIs or peers leaves from the home IP. Web UIs
# are Tailscale Services as usual
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
# State is one dataset per app under rpool/crypt/data (see base/disko.nix). The
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
{ config, lib, pkgs, ... }:
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

  # qBittorrent saves here, in a subfolder per category (one per *arr). Same
  # dataset as the library (tank1/media), so imports can be hardlinks.
  downloads = "/srv/media/downloads";
  qbittorrentPort = 8080;

  # nixpkgs hardens sonarr and radarr but not lidarr or prowlarr. This is
  # sonarr's set, at mkDefault so a module's own value wins wherever it sets
  # one (and lists like SystemCallFilter aren't merged into duplicates).
  # Not MemoryDenyWriteExecute: .NET's JIT needs W+X memory.
  hardeningSettings = {
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
  hardening = lib.mapAttrs (_: lib.mkDefault) hardeningSettings;

  # Every unit in the stack: VPN-only network, the hardening above, and
  # write access to the given paths only. Each path must exist, or the unit
  # fails to start with 226/NAMESPACE.
  confine = writable: {
    vpnConfinement = {
      enable = true;
      vpnNamespace = "vpn";
    };
    # bindsTo (from VPN-Confinement) stops the app when the namespace goes,
    # but wouldn't start it again. partOf passes restarts through too, e.g.
    # when the WireGuard config changes.
    partOf = [ "vpn.service" ];
    serviceConfig = hardening // { ReadWritePaths = writable; };
  };

  # Units that write to /srv/media
  mediaWriter = {
    # Group-writable files in the library, so hardlinks and moves work
    # between apps (fs.protected_hardlinks wants write access to the file)
    serviceConfig.UMask = lib.mkForce "0002";
    # /srv/media is nofail (base/tank1.nix): stay down without it, rather than
    # report every series and film as missing, or download onto rpool.
    unitConfig.RequiresMountsFor = [ "/srv/media" ];
  };

  perApp = f: lib.mkMerge (lib.mapAttrsToList f apps);
in
{
  imports = [ ./recyclarr.nix ];

  sops.secrets = {
    # Mullvad's wg-quick config (account page → WireGuard configuration).
    # Root-only, read by the namespace's setup script.
    mullvad_wg_conf.restartUnits = [ "vpn.service" ];
  } // lib.mapAttrs' (app: _: lib.nameValuePair "${app}_api_key" { }) apps;

  # API keys from sops instead of generated on first start, so they survive
  # a reinstall and Homepage can use them (platform/homepage.nix). The *arrs read
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
    portMappings = lib.attrValues apps ++ [ qbittorrentPort ];
  };

  # Shared group for the library, so the apps and qBittorrent can all write
  # to it. Jellyfin only reads, which the mode allows.
  users.groups.media = { };

  services = lib.mkMerge [
    (perApp (app: port: {
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
    }))
    {
      # Fetches pages behind Cloudflare's challenge for Prowlarr, in a headless
      # Chromium. Prowlarr uses it as an indexer proxy for indexers tagged
      # "flaresolverr", at 127.0.0.1 (same namespace). No UI, so no Tailscale
      # Service or port mapping.
      # @see: https://wiki.servarr.com/prowlarr/settings#flaresolverr
      flaresolverr.enable = true;

      # The module installs serverConfig over qBittorrent.conf on every start,
      # so settings changed in the UI only last until the next restart: put
      # anything worth keeping here. Categories (categories.json) and torrents
      # aren't in that file, and persist.
      # @see: https://github.com/qbittorrent/qBittorrent/wiki/Explanation-of-Options-in-qBittorrent
      qbittorrent = {
        enable = true;
        group = "media";
        webuiPort = qbittorrentPort;
        serverConfig = {
          LegalNotice.Accepted = true;
          BitTorrent.Session = {
            DefaultSavePath = downloads;
            # Automatic torrent management, so a torrent added with a category
            # (as the *arrs do) saves to <DefaultSavePath>/<category>
            DisableAutoTMMByDefault = false;
            # Peers only over the tunnel. The namespace already routes nothing
            # else out, this is in case that ever changes.
            Interface = "vpn0";
            InterfaceName = "vpn0";
            # Nothing to discover on the namespace's veth
            LSDEnabled = false;
          };
          # No UPnP or NAT-PMP: there's no router in the namespace to ask, and
          # Mullvad doesn't forward ports. With a provider that does, set
          # torrentingPort and open it with vpnNamespaces.vpn.vpn.allowedTCPPorts.
          Network.PortForwardingEnabled = false;
          Preferences.WebUI = {
            AlternativeUIEnabled = true;
            RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
            # No login, as for the *arrs: Tailscale is the access control.
            # Localhost is the *arrs (same namespace), the bridge address is
            # weka itself (Tailscale Services, Homepage).
            LocalHostAuth = false;
            AuthSubnetWhitelistEnabled = true;
            AuthSubnetWhitelist = "${ns.bridgeAddress}/32";
          };
        };
      };
    }
  ];

  systemd.services = lib.mkMerge [
    (perApp (app: _: {
      ${app} = lib.mkMerge [
        # Sonarr and prowlarr get their data dir from StateDirectory, which
        # is writable anyway. Radarr and lidarr create it with tmpfiles.
        (confine (lib.optional (lib.elem app [ "radarr" "lidarr" ]) "/var/lib/${app}"))
        # Its own library folder, and the downloads to import from
        (lib.mkIf (mediaApps ? ${app}) (mediaWriter // {
          serviceConfig = mediaWriter.serviceConfig // {
            ReadWritePaths = [ mediaApps.${app} downloads ];
          };
        }))
      ];
    }))
    {
      # The module's own hardening wins where it sets a value: it lets
      # Chromium create the namespaces its sandbox needs
      flaresolverr = lib.mkMerge [
        (confine [ ])
        {
          # A Chromium per solve: ~200 MB idle, ~500 MB during one. weka has
          # no swap, so without a cap a leak or a pile of solves would get
          # the kernel's OOM killer picking from anything on the box. Over
          # MemoryHigh it's reclaimed and slowed; over MemoryMax only it is
          # killed, and Restart=always brings it back.
          serviceConfig = {
            MemoryHigh = "1G";
            MemoryMax = "1536M";
          };
        }
      ];

      qbittorrent = lib.mkMerge [
        (confine [ config.services.qbittorrent.profileDir downloads ])
        mediaWriter
        # Where the module sets its own, weaker, value
        {
          serviceConfig = {
            ProtectSystem = lib.mkForce "strict";
            SystemCallFilter = lib.mkForce hardeningSettings.SystemCallFilter;
            # The module turns it off (see the qBittorrent PR it links), but
            # under ProtectSystem=strict the host's /tmp would be read-only.
            # Nothing here hands it files through /tmp.
            PrivateTmp = lib.mkForce true;
          };
        }
      ];
    }
  ];

  weka.tailscaleServices = lib.mapAttrs
    (_: port: { host = ns.namespaceAddress; inherit port; })
    (apps // { qbittorrent = qbittorrentPort; });
}
