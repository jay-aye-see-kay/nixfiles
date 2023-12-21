{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    neovim-flake.url = "github:jay-aye-see-kay/neovim-flake";
    flake-utils.url = "github:numtide/flake-utils";
    arion.url = "github:hercules-ci/arion";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, arion, ... }@inputs:
    let
      inherit (nixpkgs) lib;
      inherit ((import ./utils.nix inputs)) mkPkgs mkPkgCfg eachMySystem mkHmConfigMod;
      username = "jack";
      mkHmConfig = home-manager.lib.homeManagerConfiguration;
    in
    {
      formatter = eachMySystem (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      # work laptop
      homeConfigurations."${username}@jjack-XMW16X" = mkHmConfig rec {
        pkgs = mkPkgs "aarch64-darwin";
        modules =
          (mkHmConfigMod { inherit username; isDarwin = true; })
          ++ [ ({ pkgs, ... }: { home.packages = [ pkgs.silk-cli ]; }) ]
          ++ [ ({ pkgs, ... }: { home.packages = import ./features/cli-utils.nix { inherit pkgs; }; }) ];
      };

      # work vm
      homeConfigurations."${username}@moa" = mkHmConfig rec {
        pkgs = mkPkgs "aarch64-linux";
        modules =
          (mkHmConfigMod { inherit username; })
          ++ [ ./users/jack/sway ];
      };
      nixosConfigurations.moa = nixpkgs.lib.nixosSystem rec {
        system = "aarch64-linux";
        modules = [
          (mkPkgCfg system)
          ./hosts/moa
          ./features/common.nix
          ./features/fonts.nix
          ./features/sway-desktop.nix
          ./features/syncthing.nix
        ];
      };

      # home laptop
      homeConfigurations."${username}@tui" = mkHmConfig rec {
        pkgs = mkPkgs "x86_64-linux";
        modules =
          (mkHmConfigMod { inherit username; })
          ++ [ ./users/jack/sway ]
        ;
      };
      nixosConfigurations.tui = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          (mkPkgCfg system)
          nixos-hardware.nixosModules.lenovo-thinkpad-x1-6th-gen
          ./hosts/tui
          ./features/common.nix
          ./features/firefox.nix
          ./features/fonts.nix
          ./features/games.nix
          ./features/gui-utils.nix
          ./features/key-remapping.nix
          ./features/sway-desktop.nix
          ./features/syncthing.nix
        ];
      };

      # home server
      homeConfigurations."${username}@kakapo" = mkHmConfig rec {
        pkgs = mkPkgs "x86_64-linux";
        modules = mkHmConfigMod { inherit username; };
      };
      nixosConfigurations.kakapo = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          (mkPkgCfg system)
          arion.nixosModules.arion
          ./hosts/kakapo
          ./features/common.nix
          ./features/key-remapping.nix
          ./features/syncthing.nix
        ];
      };

      # small arm server on aws for file sync
      nixosConfigurations.pukeko = nixpkgs.lib.nixosSystem rec {
        system = "aarch64-linux";
        modules = [
          (mkPkgCfg system)
          ./hosts/pukeko
          ./features/common.nix
        ];
      };

    };
}
