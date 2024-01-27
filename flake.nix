{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    neovim-flake.url = "github:jay-aye-see-kay/neovim-flake";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, ... }@inputs:
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
      nixosConfigurations.moa = nixpkgs.lib.nixosSystem rec {
        system = "aarch64-linux";
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
