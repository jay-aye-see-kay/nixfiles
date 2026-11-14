# Homepage at https://home.tarpan-krait.ts.net: a start page for everything
# weka serves over Tailscale. It has no login of its own; Tailscale is the
# access control, same as every other service here.
#
# The service list is generated from weka.tailscaleServices, so anything new
# turns up on its own (under "Other", with a link and an up/down dot). Each
# app sets `weka.homepage.<name>` in its own file to give its card a group,
# icon, description or widgets (see the option below).
# Widgets query the apps from the server side, so any API keys stay on weka.
# @see: https://gethomepage.dev/configs/services/
# @see: https://gethomepage.dev/widgets/
{ config, lib, ... }:
let
  cfg = config.weka.homepage;
  port = 8082;
  tailnet = "tarpan-krait.ts.net";

  # Groups, in display order, and how many cards per row
  groups = [
    { name = "Apps"; columns = 3; }
    { name = "Downloads"; columns = 4; }
    { name = "Monitoring"; columns = 3; }
    { name = "Other"; columns = 3; }
  ];

  services = lib.removeAttrs config.weka.tailscaleServices [ "home" ];
  card = name: svc:
    let m = cfg.${name} or { }; in {
      ${m.title or (lib.toUpper (lib.substring 0 1 name) + lib.substring 1 (-1) name)} = {
        href = "https://${name}.${tailnet}";
        icon = m.icon or "${name}.svg";
        # Straight to the app, not through Tailscale
        siteMonitor = "http://${svc.host}:${toString svc.port}${m.monitorPath or ""}";
      }
      // lib.optionalAttrs (m ? description) { inherit (m) description; }
      // lib.optionalAttrs (m ? widgets) { inherit (m) widgets; };
    };
  inGroup = group: lib.mapAttrsToList card
    (lib.filterAttrs (name: _: (cfg.${name}.group or "Other") == group) services);
in
{
  # Icons by name come from https://github.com/homarr-labs/dashboard-icons,
  # loaded by the browser from a CDN.
  options.weka.homepage = lib.mkOption {
    type = lib.types.attrsOf lib.types.attrs;
    default = { };
    example = {
      readeck = {
        group = "Apps";
        description = "Saved articles";
        monitorPath = "/api/info";
      };
    };
    description = ''
      Card details for a Tailscale Service, by service name: group (one of
      the groups above, default "Other"), title, icon, description, widgets,
      and monitorPath, for when / doesn't answer the up/down check with a
      plain 2xx/3xx. A service with no entry still gets a card.
    '';
  };

  config = {
    services.homepage-dashboard = {
      enable = true;
      listenPort = port;
      allowedHosts = "home.${tailnet},127.0.0.1:${toString port},localhost:${toString port}";

      settings = {
        title = "weka";
        theme = "dark";
        color = "slate";
        headerStyle = "clean";
        statusStyle = "dot";
        hideVersion = true;
        disableUpdateCheck = true;
        layout = lib.listToAttrs (map
          (g: lib.nameValuePair g.name { style = "row"; inherit (g) columns; })
          groups);
      };

      services = lib.filter (g: lib.head (lib.attrValues g) != [ ])
        (map (g: { ${g.name} = inGroup g.name; }) groups);

      widgets = [
        {
          resources = {
            label = "weka";
            cpu = true;
            memory = true;
            uptime = true;
            cputemp = true;
            units = "metric";
            network = "lan0";
          };
        }
        {
          datetime = {
            text_size = "md";
            format = { dateStyle = "long"; timeStyle = "short"; hour12 = false; };
          };
        }
      ];

      bookmarks = [
        {
          Admin = [
            { Tailscale = [{ icon = "tailscale-light.svg"; href = "https://login.tailscale.com/admin/services"; }]; }
            { "Healthchecks.io" = [{ icon = "healthchecks.svg"; href = "https://healthchecks.io/"; }]; }
          ];
        }
      ];
    };

    # The module leaves HOSTNAME unset, and Homepage then listens on 0.0.0.0.
    # The firewall would block it, but keep it on localhost like everything else.
    systemd.services.homepage-dashboard.environment.HOSTNAME = "127.0.0.1";

    weka.tailscaleServices.home = port;
  };
}
