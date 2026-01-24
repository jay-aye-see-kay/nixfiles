{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    neovim-flake.url = "path:./neovim";
    neovim-flake.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { nixpkgs, nixos-hardware, home-manager, ... }@inputs:
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
          ./users/jack/home.nix
          ./modules/home-manager
          ({ pkgs, ... }: {
            nix.registry.nixpkgs.flake = inputs.nixpkgs;
            modules.devtools.enable = true;
            modules.cli-utils.enable = true;
            home = {
              username = "jack";
              stateVersion = "22.05";
              homeDirectory = "/Users/jack";
            };
          })
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
          ./modules/nixos
          {
            modules.cli-utils.enable = true;
            modules.firefox.enable = true;
            modules.fonts.enable = true;
            modules.games.enable = true;
            modules.gui-utils.enable = true;
            modules.key-remapping.enable = true;
            modules.sway-desktop.enable = true;
            modules.syncthing.enable = true;
          }
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.jack = {
                imports = [
                  ./users/jack/home.nix
                  ./users/jack/sway
                  ./modules/home-manager
                ];
                modules.devtools.enable = true;
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
