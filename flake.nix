{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, nixpkgs-unstable, nixos-hardware, home-manager, ... }@inputs:
    let
      username = "jack";

      # Systems this config supports
      mySystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper to build attrset for each system (used for formatter)
      eachMySystem = mkConfig: (nixpkgs.lib.lists.fold
        (system: accum: accum // { ${system} = mkConfig system; })
        { }
        mySystems);

      # Import unstable once per system (no overlay needed!)
      pkgsUnstable = {
        "x86_64-linux" = import nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        "aarch64-darwin" = import nixpkgs-unstable {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
      };
    in
    {
      formatter = eachMySystem (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      # work laptop (macOS)
      homeConfigurations."${username}@jjack-XMW16X" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config = { allowUnfree = true; };
          overlays = [ ];
        };
        extraSpecialArgs = {
          pkgs-unstable = pkgsUnstable."aarch64-darwin";
        };
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

      # home laptop (NixOS)
      nixosConfigurations.tui = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          pkgs-unstable = pkgsUnstable."x86_64-linux";
        };
        modules = [
          { nixpkgs.config.allowUnfree = true; }
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
              extraSpecialArgs = {
                pkgs-unstable = pkgsUnstable."x86_64-linux";
              };
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
