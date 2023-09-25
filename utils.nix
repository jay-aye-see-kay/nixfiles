#
# This file is only useful for the main flake.nix file, it expects the flake inputs
# as it's parameter
#
{ nixpkgs, nixpkgs-unstable, neovim-flake, ... }: rec {
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
  # boilerplate for home manager config
  #
  mkHmConfigMod = { username, isDarwin ? false, stateVersion ? "22.05" }: [
    ./users/${username}/home.nix
    {
      home.username = username;
      home.homeDirectory = "/${if isDarwin then "Users" else "home"}/${username}";
      home.stateVersion = stateVersion;
    }
  ];

  #
  # adding stuff that's not in nixpkgs
  #
  myPkgsOverlay = final: prev: {
    # stuff from npm
    customNodePackages = import ./node-packages/default.nix { pkgs = prev; };

    # silk-cli (only used on cultureamp laptop)
    silk-cli =
      let
        version = "2.28.0";
        rev = "6e2bbcb5e4852041ac85ebaf7f0504fd3a3ade71";
      in
      prev.buildGoModule rec {
        inherit version;
        pname = "silk";
        src = builtins.fetchGit {
          inherit rev;
          url = "ssh://git@github.com/cultureamp/silk.git";
        };
        ldflags = [ "-s" "-w" "-X main.version=${version}" "-X main.commit=${rev}" "-X main.builtBy=nix" ];
        # To get a new sha: `vendorSha256 = prev.lib.fakeSha256`
        vendorSha256 = "sha256-/1u/CDc0GNPQqv6gYE9x0Y+ZvtURXgurJssUZiJUlo0=";
      };
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
        neovim-flake.overlays.${system}.default
      ];
    };

}
