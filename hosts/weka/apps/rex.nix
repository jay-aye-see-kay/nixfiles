# Rex server, so Rex on the Mac can open sessions on weka. Add it there with
# Add Remote Host…: weka.tarpan-krait.ts.net (Tailscale, port 7297), or
# ssh://jack@weka as a fallback. Both reach the same server and sessions.
#
# The login server runs as root, identifies each caller by their Tailscale
# login, and hands them a server running as their own account. Not a Tailscale
# Service (platform/tailscale-services.nix): the module serves it on port 7297
# of weka's own tailnet name, and only touches that mapping.
# @see: https://www.superlogical.com/rex/docs/linux/login-server
# @see: https://www.superlogical.com/rex/docs/linux/remote-access#tailscale-serve
_:
{
  services.rex.loginServer = {
    enable = true;
    accounts.jack.principals = [ "tailscale:jay-aye-see-kay@github" ];
    tailscaleServe.enable = true;
  };

  # Both units rewrite tailscaled's serve config, and running at the same time
  # makes one fail with "etag mismatch"
  systemd.services.rex-tailscale-serve.after = [ "tailscale-services.service" ];

  # Keep jack's server (and its sessions) running while logged out and
  # from boot, rather than only during a login session.
  users.users.jack.linger = true;

  # The server reads init.lua, so the Mac's bindings only apply to sessions on
  # weka if weka has a copy. A store copy, so run `rex config reload` on weka
  # after deploying a change. Some bindings don't work here yet, see the note in
  # modules/home-manager/rex.nix.
  # TODO: move to home-manager once weka has it for jack.
  systemd.tmpfiles.rules = [
    "d /home/jack/.config 0755 jack users -"
    "d /home/jack/.config/rex 0755 jack users -"
    "L+ /home/jack/.config/rex/init.lua - - - - ${../../../dots/rex/init.lua}"
  ];
}
