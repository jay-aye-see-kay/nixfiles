# Percy, a read-only AI agent living in Slack's #percy channel on weka.
#
# Every message in #percy prompts it; each Slack thread is its own context
# window, persisted under /var/lib/percy/sessions (its own ZFS dataset), so
# threads survive restarts and idle eviction. Replies are posted back into
# the thread. It is read-only: the pi SDK session exposes read/grep/find/ls
# plus the codemode-reached `percy` tool namespace (systemd journal today;
# prometheus, alerts and friends later).
#
# Slack connectivity is Socket Mode only: an outbound WebSocket, so nothing
# on weka is exposed and there is no Tailscale Service. The Slack app needs
# bot scopes chat:write, channels:history, channels:read, reactions:write,
# and connections:write (app-level, for Socket Mode), with event
# subscriptions for message.channels.
#
# Secrets (sops): slack_bot_token, slack_app_token, opencode_api_key.
# The model is opencode-go/glm-5.3-flash, reachable via OPENCODE_API_KEY.
{ config, pkgs, ... }:
let
  app = pkgs.callPackage ./app { };
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
      ProtectHome = "read-only";
      PrivateTmp = true;
      # Percy logs to stdout (and can read its own journal entries)
    };
  };

  weka.datasets."data/percy" = "/var/lib/private/percy";
}
