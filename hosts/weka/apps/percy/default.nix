# Percy, a read-only AI agent living in Slack's #percy channel on weka.
#
# Every message in #percy prompts it; each Slack thread is its own context
# window, persisted under /var/lib/percy/sessions (its own ZFS dataset), so
# threads survive restarts and idle eviction. It is read-only: the pi SDK
# session exposes read/grep/find/ls plus the codemode-reached `percy` tool
# namespace (Loki logs, Prometheus metrics and alerts, systemd units, and the
# journal as a fallback).
#
# What it can read: Home Assistant's YAML config, generated unit files, and
# the rest of the filesystem minus what the sandbox below hides. Everything
# percy reads goes to the model provider, so secrets stay out of reach: most
# of /var/lib is world-readable, including HA's secrets.yaml, integration
# credentials (.storage) and the *arr API keys. (The repo isn't on weka;
# putting it in the closure would change weka's hash on every commit.)
#
# Replies use Slack's agent UI: the thread becomes an agent session (loading
# indicator and stop button while percy works), and the reply is one streamed
# message with a task card per tool call, ending in feedback buttons
# (recorded in /var/lib/percy/feedback.jsonl).
#
# Slack connectivity is Socket Mode only: an outbound WebSocket, so nothing
# on weka is exposed and there is no Tailscale Service. The Slack app needs
# bot scopes chat:write, channels:history, channels:read and users:read (to
# label messages with the speaker's name), app-level connections:write (for
# Socket Mode), event subscriptions for message.channels and
# agent_session_stopped (the stop button), Interactivity on (feedback
# buttons), and the Agents feature enabled in the app settings.
#
# Secrets (sops): slack_bot_token, slack_app_token, opencode_api_key.
# The model is opencode-go/glm-5.3-flash, reachable via OPENCODE_API_KEY.
{ config, pkgs, ... }:
let
  app = pkgs.callPackage ./app { };
  hass = "/var/lib/hass";
in
{
  sops.secrets = {
    slack_bot_token = { };
    slack_app_token = { };
    opencode_api_key = { };
  };
  sops.templates."percy.env" = {
    content = ''
      SLACK_BOT_TOKEN=${config.sops.placeholder.slack_bot_token}
      SLACK_APP_TOKEN=${config.sops.placeholder.slack_app_token}
      OPENCODE_API_KEY=${config.sops.placeholder.opencode_api_key}
    '';
    restartUnits = [ "percy.service" ];
  };

  systemd.services.percy = {
    description = "Percy: read-only pi agent in Slack's #percy channel";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    # pi's grep and find tools shell out to rg and fd, and download them from
    # GitHub at runtime if they're not on PATH
    path = [ pkgs.ripgrep pkgs.fd ];
    environment = {
      PERCY_PROMETHEUS_URL = "http://127.0.0.1:${toString config.services.prometheus.port}";
      PERCY_ALERTMANAGER_URL = "http://127.0.0.1:${toString config.services.prometheus.alertmanager.port}";
      PERCY_LOKI_URL = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
    };
    serviceConfig = {
      DynamicUser = true;
      # Reading the journal needs the journal group
      SupplementaryGroups = [ "systemd-journal" ];
      StateDirectory = "percy";
      EnvironmentFile = config.sops.templates."percy.env".path;
      ExecStart = "${app}/bin/percy";
      Restart = "on-failure";
      RestartSec = "10s";
      # Read-only agent: the filesystem and journal are readable, StateDirectory
      # is the only writable path
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      # An allowlist for app state: /var/lib and /srv are empty except for
      # HA's config and percy's StateDirectory (which systemd mounts on
      # top). HA's dir is bound whole, not file by file, because HA replaces
      # files by rename, which a file bind wouldn't follow. Inside it, .storage
      # (integration credentials), backups, secrets.yaml and the Zigbee DB
      # (network key) are hidden. HA never rewrites secrets.yaml, so masking
      # that file stays put.
      TemporaryFileSystem = [
        "/var/lib:ro"
        "/srv:ro"
        "${hass}/.storage:ro"
        "${hass}/backups:ro"
        "${hass}/.cloud:ro"
      ];
      BindReadOnlyPaths = [ hass ];
      InaccessiblePaths = map (f: "-${hass}/${f}") [
        "secrets.yaml"
        "zigbee.db"
        "zigbee.db-wal"
        "zigbee.db-shm"
      ];
      # Percy logs to stdout (and can read its own journal entries)
    };
  };

  weka.datasets."data/percy" = "/var/lib/private/percy";
}
