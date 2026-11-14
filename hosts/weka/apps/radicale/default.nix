# Radicale (CalDAV), at https://radicale.tarpan-krait.ts.net, as an inbox for
# Mealie's shopping list. Each phone has it as a CalDAV account in Reminders
# with a list called "Shopping", so Siri's own "add beans to the shopping
# list" works. The sync below moves each new reminder onto the Mealie list and
# deletes it, so the Reminders list stays empty and Mealie is the real list.
#
# Each person is their own Radicale user, logged in from their Tailscale
# identity: nginx turns Tailscale-User-Login into X-Remote-User for the logins
# in `users`, and refuses everyone else. iOS insists on a username and
# password when adding the account, but anything works, since the header wins.
# The server has to be the full https://radicale.tarpan-krait.ts.net/: with
# just the host name, iOS never reaches weka and says it can't use SSL.
#
# Nothing here is kept for long, so no ZFS dataset or backup.
# @see: https://radicale.org/v3.html
{ config, lib, pkgs, ... }:
let
  port = 5232;
  proxyPort = 5233;
  # Tailnet logins, which are also the Mealie usernames (apps/mealie.nix)
  users = [ "jay-aye-see-kay@github" "nora.ns.schneider@gmail.com" ];
  storage = "/var/lib/radicale/collections";
  # Touched by Radicale after every change, to start the sync
  trigger = "${storage}/.sync-trigger";
in
{
  services.radicale = {
    enable = true;
    settings = {
      server.hosts = [ "127.0.0.1:${toString port}" ];
      # Trusts whichever user the header names, so anything on weka could
      # claim to be anyone. Same trade-off as Grafana (monitoring/grafana.nix).
      auth.type = "http_x_remote_user";
      storage.filesystem_folder = storage;
      # Runs while Radicale holds its write lock, so it can't call Radicale
      # itself: just poke the path unit.
      storage.hook = "${pkgs.coreutils}/bin/touch ${trigger}";
    };
  };

  services.nginx = {
    enable = true;
    appendHttpConfig = ''
      map $http_tailscale_user_login $radicale_user {
        default "";
        ${lib.concatMapStrings (user: ''"${user}" "${user}";'' + "\n") users}
      }
    '';
    virtualHosts.radicale = {
      listen = [{ addr = "127.0.0.1"; port = proxyPort; }];
      # Otherwise nginx's own redirects (/.web to /.web/) point at
      # http://<host>:${toString proxyPort}, past tailscale serve
      extraConfig = "absolute_redirect off;";
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        extraConfig = ''
          if ($radicale_user = "") {
            return 403;
          }
          proxy_set_header X-Remote-User $radicale_user;
        '';
      };
      # The web UI's static files, open so Homepage's up/down check has
      # something to hit. Everything it does after loading needs a login.
      locations."/.web/".proxyPass = "http://127.0.0.1:${toString port}";
    };
  };

  weka.tailscaleServices.radicale = proxyPort;

  systemd.services.mealie-shopping-sync = {
    description = "Move Reminders shopping items from Radicale to Mealie";
    after = [ "radicale.service" "mealie.service" ];
    environment = {
      RADICALE_URL = "http://127.0.0.1:${toString port}";
      MEALIE_URL = "http://127.0.0.1:${toString config.services.mealie.port}";
      SYNC_USERS = lib.concatStringsSep " " users;
      LIST_NAME = "Shopping";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 -I ${./shopping-sync.py}";
      LoadCredential = "mealie-proxy-secret:${config.sops.secrets.mealie_proxy_secret.path}";
      DynamicUser = true;
      IPAddressAllow = "localhost";
      IPAddressDeny = "any";
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      CapabilityBoundingSet = "";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateUsers = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      RestrictNamespaces = true;
      RestrictRealtime = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [ "@system-service" "~@privileged" ];
    };
  };

  systemd.paths.mealie-shopping-sync = {
    wantedBy = [ "paths.target" ];
    pathConfig.PathChanged = trigger;
  };

  # Catches anything the path unit missed, like items added while Mealie was
  # down, which stay in Radicale until they're on the list
  systemd.timers.mealie-shopping-sync = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # Not OnBootSec: on a deploy that has long passed, so it fires at once,
      # while Radicale and Mealie are still restarting
      OnActiveSec = "2min";
      OnUnitInactiveSec = "5min";
    };
  };

  weka.homepage.radicale = {
    group = "Apps";
    description = "Reminders inbox for the Mealie shopping list";
    # Everything else needs a Tailscale login
    monitorPath = "/.web/";
  };
}
