{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";
    mac-app-util.url = "github:hraban/mac-app-util";

    neovim-flake.url = "path:./neovim";
    neovim-flake.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { nixpkgs, nixos-hardware, home-manager, mac-app-util, ... }@inputs:
    let
      inherit ((import ./utils.nix inputs)) mkPkgs mkPkgCfg eachMySystem;
      username = "jack";
      mkHmConfig = home-manager.lib.homeManagerConfiguration;
    in
    {
      formatter = eachMySystem (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      # work laptop
      homeConfigurations."${username}@jjack-XMW16X" = mkHmConfig {
        pkgs = mkPkgs "aarch64-darwin";
        modules = [
          mac-app-util.homeManagerModules.default
          ./users/jack/home.nix
          ({ pkgs, ... }: {
            nix.registry.nixpkgs.flake = inputs.nixpkgs;
            home = {
              username = "jack";
              stateVersion = "22.05";
              homeDirectory = "/Users/jack";
              packages = import ./features/cli-utils.nix { inherit pkgs; };
            };
          })
        ];
      };

      # work vm
      nixosConfigurations.moa = nixpkgs.lib.nixosSystem rec {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          (mkPkgCfg system)
          ./hosts/moa
          ./features/common.nix
          ./features/fonts.nix
          ./features/sway-desktop.nix
          ./features/syncthing.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.jack = {
                imports = [
                  ./users/jack/home.nix
                  ./users/jack/sway
                ];
                home.username = "jack";
                home.stateVersion = "22.05";
                home.homeDirectory = "/home/jack";
              };
            };
          }
        ];
      };

      # home laptop
      nixosConfigurations.tui = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
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
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.jack = {
                imports = [
                  ./users/jack/home.nix
                  ./users/jack/sway
                ];
                home.username = "jack";
                home.stateVersion = "22.05";
                home.homeDirectory = "/home/jack";
              };
            };
          }
        ];
      };

      # home server
      nixosConfigurations.kakapo = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          (mkPkgCfg system)
          ./hosts/kakapo
          ./features/common.nix
          ./features/key-remapping.nix
          ./features/syncthing.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.jack = {
                imports = [
                  ./users/jack/home.nix
                ];
                home.username = "jack";
                home.stateVersion = "22.05";
                home.homeDirectory = "/home/jack";
              };
            };
          }
        ];
      };

    };
}
