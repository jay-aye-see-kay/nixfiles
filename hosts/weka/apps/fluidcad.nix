# FluidCAD (parametric CAD in the browser) as the upstream container (podman).
# Tailnet: https://fluidcad.tarpan-krait.ts.net (a Tailscale Service). The
# geometry kernel runs here; the browser only renders.
#
# Its Agent panel runs Claude Code on the Claude subscription. The image has no
# Claude Code, so the nixpkgs one is mounted in with the (read-only) store and
# put on PATH. It must be signed in once, as the container's user:
#   sudo podman exec -it fluidcad claude auth login
# The login lands in /var/lib/fluidcad/home/.claude and Claude Code refreshes it.
#
# No sign-in (FLUIDCAD_NO_AUTH): anyone on the tailnet who can reach the Service
# can run code here through a model file and use the Claude plan. Restrict it
# with tailnet ACLs if that's more than me.
#
# Upgrades: bump `tag`. Projects pin their engine version, and the start screen
# offers to move them (older engines are downloaded into home/.fluidcad).
# Claude Code must be >= 2.1.259, so it comes from unstable.
# @see: https://fluidcad.io/docs/installation#docker
# @see: https://fluidcad.io/docs/agent
{ pkgs-unstable, ... }:
let
  port = 3100;
  tag = "0.0.52";
  dataDir = "/var/lib/fluidcad";
  # Fixed, so files written in the container map to the fluidcad user here
  uid = 3100;
in
{
  users.users.fluidcad = {
    inherit uid;
    isSystemUser = true;
    group = "fluidcad";
    home = "${dataDir}/home";
  };
  users.groups.fluidcad.gid = uid;

  virtualisation.oci-containers = {
    backend = "podman";
    containers.fluidcad = {
      image = "ghcr.io/fluid-cad/fluidcad:${tag}";
      ports = [ "127.0.0.1:${toString port}:3100" ];
      user = "${toString uid}:${toString uid}";
      volumes = [
        "${dataDir}/projects:/app/projects"
        # HOME: ~/.fluidcad (engines, recents, previews) and Claude's login
        "${dataDir}/home:/home/node"
        "/nix/store:/nix/store:ro"
      ];
      environment = {
        HOME = "/home/node";
        # node is in /usr/local/bin in the image
        PATH = "${pkgs-unstable.claude-code}/bin:/usr/local/bin:/usr/bin:/bin";
        FLUIDCAD_NO_AUTH = "1";
        # The origin pages are served from (Tailscale terminates TLS), and the
        # only non-loopback Host it answers to. Loopback is always allowed,
        # which Homepage's monitor uses.
        FLUIDCAD_PUBLIC_URL = "https://fluidcad.tarpan-krait.ts.net";
      };
      extraOptions = [
        # Same reason as home-assistant: stop with the unit, not as a separate
        # scope that systemd SIGTERMs all at once
        "--cgroups=split"
      ];
    };
  };

  systemd.services.podman-fluidcad = {
    unitConfig.RequiresMountsFor = [ dataDir ];
    # Not tmpfiles: it runs before a fresh dataset is mounted (see README.md)
    preStart = ''
      install -d -o fluidcad -g fluidcad ${dataDir}/projects ${dataDir}/home
    '';
  };

  weka.tailscaleServices.fluidcad = port;

  weka.datasets."data/fluidcad" = dataDir;
  weka.homepage.fluidcad = {
    group = "Apps";
    title = "FluidCAD";
    description = "Parametric CAD";
  };
}
