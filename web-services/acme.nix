# Generate wildcard cert for h.jackrose.co.nz
# see: https://nixos.org/manual/nixos/stable/index.html#module-security-acme-config-dns
#
# doesn't currently work, getting the error `unexpected response code 'SERVFAIL' for _acme-challenge.h.jackrose.co.nz.`
# on non-nixos systems this seems to be a permissions error, maybe it is here too?
{ config, pkgs, lib, ... }:
{
  services.bind =
    {
      enable = true;
      extraConfig = ''
        include "/var/lib/secrets/dnskeys.conf";
      '';
      zones = [
        rec {
          name = "h.jackrose.co.nz";
          file = "/var/db/bind/${name}";
          master = true;
          extraConfig = "allow-update { key rfc2136key.h.jackrose.co.nz.; };";
        }
      ];
    };

  # Now we can configure ACME
  security.acme.acceptTerms = true;
  security.acme.email = "user+acme@jackrose.co.nz";
  security.acme.certs."h.jackrose.co.nz" = {
    domain = "*.h.jackrose.co.nz";
    dnsProvider = "rfc2136";
    credentialsFile = "/var/lib/secrets/certs.secret";
    # We don't need to wait for propagation since this is a local DNS server
    dnsPropagationCheck = false;
  };
}
