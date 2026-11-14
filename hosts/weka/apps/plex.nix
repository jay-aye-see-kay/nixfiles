# Plex, kept as a fallback for the PS5 (no Jellyfin app), on the LAN only.
# State is its own dataset, rpool/crypt/data/plex (see base/disko.nix). It holds
# the server's claim, so restoring it keeps the same server in the Plex
# account. Remote access is off in its settings. The media is on tank1 at
# /srv/media.
# @see: https://wiki.nixos.org/wiki/Plex
{
  services.plex = {
    enable = true;
    # Its list opens every interface; only the LAN is wanted
    openFirewall = false;
  };

  systemd.services.plex.unitConfig.RequiresMountsFor = [ "/srv/media" ];

  networking.firewall.interfaces.lan0 = {
    allowedTCPPorts = [ 32400 ];
    # GDM, so the PS5 finds the server on the LAN
    allowedUDPPorts = [ 32410 32412 32413 32414 ];
  };

  # Rebuilt by Plex as needed
  services.restic.backups.weka.exclude = [
    "/var/lib/plex/.zfs/snapshot/restic/Plex Media Server/Cache"
    "/var/lib/plex/.zfs/snapshot/restic/Plex Media Server/Crash Reports"
  ];
}
