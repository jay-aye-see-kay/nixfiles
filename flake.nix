{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-21.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, sops-nix, neovim-nightly-overlay }:
    let
      username = "jack";
      system = "x86_64-linux";
      systemDarwin = "x86_64-darwin";
      overlay-unstable = final: prev: {
        unstable = nixpkgs-unstable.legacyPackages.${prev.system};
      };
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [
          overlay-unstable
          neovim-nightly-overlay.overlay
        ];
      };
      pkgsDarwin = import nixpkgs {
        system = systemDarwin;
        config = { allowUnfree = true; };
        overlays = [
          overlay-unstable
          neovim-nightly-overlay.overlay
        ];
      };
      lib = nixpkgs.lib;
      homeManagerImports = [
        ./users/jack/home.nix
        ./users/jack/fish.nix
        ./users/jack/neovim
      ];
    in
    {
      homeManagerConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit system pkgs username;
        homeDirectory = "/home/${username}";
        configuration.imports = homeManagerImports;
      };

      homeManagerConfigurations."${username}-mbp" = home-manager.lib.homeManagerConfiguration {
        inherit username;
        pkgs = pkgsDarwin;
        system = systemDarwin;
        homeDirectory = "/Users/${username}";
        configuration.imports = homeManagerImports ++ [
          ./users/jack/fish-macos-fix.nix
        ];
      };

      nixosConfigurations = {
        tui = lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/tui
          ];
        };

        kakapo = lib.nixosSystem {
          inherit system;
          modules = [
            sops-nix.nixosModules.sops
            ./secrets/sops.nix
            ./hosts/kakapo
            ./web-services
          ];
        };

      };
    };
}
