# The LAN: one onboard NIC (lan0) with one address, 192.168.10.101, from a
# fixed lease in UniFi (by MAC).
#
# systemd-networkd runs in both the initrd (for the clevis/Tang and SSH
# unlock, see unlock.nix) and stage 2, from the same definition. This is the
# setup nixpkgs expects with a systemd initrd: the initrd's address, routes
# and network-online.target carry over at switch-root, and stage-2 networkd
# takes over the same lease. DNS goes through systemd-resolved, so
# /etc/resolv.conf is always the 127.0.0.53 stub. Upstream servers come from
# the DHCP lease, and from MagicDNS once Tailscale is up (it configures
# resolved over D-Bus rather than rewriting resolv.conf).
{ lib, ... }:
let
  lan = {
    matchConfig.Name = "lan0";
    networkConfig.DHCP = "yes";
    # The initrd has no persistent machine-id, so the default DUID-based
    # client ID would change every boot, and differ from stage 2's. The MAC
    # doesn't, so both stages ask for the same lease.
    dhcpV4Config = {
      ClientIdentifier = "mac";
      # The hostname is set in Nix. Without this networkd tries to apply the
      # one DHCP offers, and logs "Could not set hostname" in both stages.
      UseHostname = false;
    };
  };
in
{
  networking = {
    useNetworkd = true;
    # Only lan0 is configured (above). Without this nixpkgs adds a catch-all
    # DHCP network for every physical Ethernet interface.
    useDHCP = lib.mkDefault false;
  };

  systemd.network.networks."10-lan" = lan;
  boot.initrd.systemd.network.networks."10-lan" = lan;

  # A fixed name for the onboard NIC. The kernel's name comes from the PCI
  # path, so it would change with the board or slot. Everything else refers to
  # lan0. Matched on the driver rather than Type=ether, which would also catch
  # virtual Ethernet devices (VPN-Confinement's veth-vpn-br, or podman's if a
  # container ever uses a bridge network).
  # nixpkgs copies .link files into the initrd too, so the unlock network
  # gets the same name.
  systemd.network.links."10-lan0" = {
    matchConfig.Driver = "r8169";
    linkConfig.Name = "lan0";
  };
}
