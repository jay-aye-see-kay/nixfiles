{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager.url = "github:nix-community/home-manager/release-22.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";

    neovim-flake.url = "github:jay-aye-see-kay/neovim-flake";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , nixos-hardware
    , home-manager
    , sops-nix
    , neovim-flake
    }:
    let
      inherit (nixpkgs) lib;

      username = "jack";
      mySystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

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
      eachMySystem = mkConfig: (lib.lists.fold
        (system: accum: accum // { ${system} = mkConfig system; })
        { }
        mySystems);

      # Build pkgs with all my overlays for a given system
      mkPkgs = system:
        let
          nixpkgs-unstable-overlay = final: prev: {
            unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
          };
          node-pkgs-overlay = final: prev: {
            customNodePackages = import ./node-packages/default.nix { pkgs = prev; };
          };
          cultureamp-overlay = final: prev: {
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
          authelia-overlay = final: prev: {
            authelia = import ./authelia prev;
          };
        in
        import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
          overlays = [
            nixpkgs-unstable-overlay
            node-pkgs-overlay
            cultureamp-overlay
            authelia-overlay
            neovim-flake.overlays.${system}.default
          ];
        };

      commonHomeManagerImports = [
        ./users/jack/home.nix
        ./users/jack/fish.nix
      ];
      linuxHomeManagerImports = commonHomeManagerImports ++ [ ./users/jack/i3 ];
      darwinHomeManagerImports = commonHomeManagerImports;

      mkHmConfig = home-manager.lib.homeManagerConfiguration;

      mkHmConfigMod = { username, isDarwin ? false }: [{
        home.username = username;
        home.homeDirectory = "/${if isDarwin then "Users" else "home"}/${username}";
        home.stateVersion = "22.05";
      }];
    in
    {
      formatter = eachMySystem (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      # work laptop
      homeConfigurations."${username}@jjack-XMW16X" = mkHmConfig rec {
        pkgs = mkPkgs "aarch64-darwin";
        modules = darwinHomeManagerImports
          ++ [ ({ pkgs, ... }: { home.packages = [ pkgs.silk-cli ]; }) ]
          ++ mkHmConfigMod { inherit username; isDarwin = true; };
      };

      # work vm
      homeConfigurations."${username}@moa" = mkHmConfig rec {
        pkgs = mkPkgs "aarch64-linux";
        modules = linuxHomeManagerImports ++ mkHmConfigMod { inherit username; };
      };
      nixosConfigurations.moa = let system = "aarch64-linux"; in
        lib.nixosSystem {
          inherit system;
          pkgs = mkPkgs system;
          modules = [ ./hosts/moa ./features/fonts.nix ];
        };

      # home laptop
      homeConfigurations."${username}@tui" = mkHmConfig rec {
        pkgs = mkPkgs "x86_64-linux";
        modules = linuxHomeManagerImports ++ mkHmConfigMod { inherit username; };
      };
      nixosConfigurations.tui = let system = "x86_64-linux"; in
        lib.nixosSystem {
          inherit system;
          pkgs = mkPkgs system;
          modules = [
            nixos-hardware.nixosModules.lenovo-thinkpad-x1-6th-gen
            ./hosts/tui
            ./features/fonts.nix
            ./features/games.nix
            ./features/i3-desktop.nix
            ./features/key-remapping.nix
          ];
        };

      # home server
      homeConfigurations."${username}@kakapo" = mkHmConfig rec {
        pkgs = mkPkgs "x86_64-linux";
        modules = linuxHomeManagerImports ++ mkHmConfigMod { inherit username; };
      };
      homeConfigurations."hud@kakapo" = mkHmConfig rec {
        pkgs = mkPkgs "x86_64-linux";
        modules = [ ./users/hud/home.nix ] ++ mkHmConfigMod { username = "hud"; };
      };
      nixosConfigurations.kakapo = let system = "x86_64-linux"; in
        lib.nixosSystem {
          inherit system;
          pkgs = mkPkgs system;
          modules = [
            sops-nix.nixosModules.sops
            ./secrets/sops.nix
            ./hosts/kakapo
          ];
        };

      # oracle server
      homeConfigurations."${username}@possum" = mkHmConfig rec {
        pkgs = mkPkgs "aarch64-linux";
        modules = linuxHomeManagerImports ++ mkHmConfigMod { inherit username; };
      };
      nixosConfigurations.possum = let system = "aarch64-linux"; in
        lib.nixosSystem {
          inherit system;
          pkgs = mkPkgs system;
          modules = [
            sops-nix.nixosModules.sops
            ./secrets/sops.nix
            ./hosts/possum
          ];
        };

    };
}
