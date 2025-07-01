#
# This file is only useful for the main flake.nix file, it expects the flake inputs
# as it's parameter
#
{ nixpkgs, nixpkgs-unstable, ... }: rec {
  #
  # list of systems this config can support
  #
  mySystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

  #
  # Build an attrset of config for each mySystem with `system` as the keys
  # e.g.
  #     eachMySystem (system: "__${system}")
  # will return:
  #     {
  #       "x86_64-linux": "__x86_64-linux";
  #       "x86_64-darwn": "__x86_64-darwn";
  #       "aarch64-linux": "__aarch64-linux";
  #       "aarch64-darwin": "__aarch64-darwin";
  #     }
  #
  eachMySystem = mkConfig: (nixpkgs.lib.lists.fold
    (system: accum: accum // { ${system} = mkConfig system; })
    { }
    mySystems);

  #
  # adding stuff that's not in nixpkgs
  #
  myPkgsOverlay = final: prev: {
    # stuff from npm
    customNodePackages = import ./node-packages/default.nix { pkgs = prev; };
  };

  #
  # Build `pkgs` with my overlays for a given system
  #
  mkPkgs = system:
    let
      nixpkgs-unstable-overlay = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
    in
    import nixpkgs {
      inherit system;
      config = { allowUnfree = true; };
      overlays = [
        nixpkgs-unstable-overlay
        myPkgsOverlay
      ];
    };

  #
  # pkg config and overlays for a given system
  #
  mkPkgCfg = system:
    let
      nixpkgs-unstable-overlay = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
    in
    {
      nixpkgs = {
        config.allowUnfree = true;
        overlays = [
          nixpkgs-unstable-overlay
          myPkgsOverlay
        ];
      };
    };
}
