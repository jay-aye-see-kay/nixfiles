# Temporary fix for inetutils build failure on Darwin
# @see: https://github.com/NixOS/nixpkgs/issues/488689
# @see: https://github.com/NixOS/nixpkgs/pull/489909
# Remove this file once PR #489909 is merged and in your nixpkgs version
{ ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      inetutils = prev.inetutils.overrideAttrs (oldAttrs: {
        # Disable format-security hardening on Darwin
        # Upstream gnulib won't fix the format-security warnings
        hardeningDisable = (oldAttrs.hardeningDisable or [ ])
          ++ final.lib.optional final.stdenv.hostPlatform.isDarwin "format";
        
        # Disable tests on Darwin - libls.sh test fails on APFS
        doCheck = !final.stdenv.hostPlatform.isDarwin;
      });
    })
  ];
}
