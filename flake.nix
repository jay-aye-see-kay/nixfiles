{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager.url = "github:nix-community/home-manager/release-21.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixos-hardware, home-manager, sops-nix, neovim-nightly-overlay, emacs-overlay }:
    let
      username = "jack";
      system = "x86_64-linux";
      systemDarwin = "x86_64-darwin";
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [
          overlay-unstable
          neovim-nightly-overlay.overlay
          emacs-overlay.overlay
        ];
      };
      pkgsDarwin = import nixpkgs {
        system = systemDarwin;
        config = { allowUnfree = true; };
        overlays = [
          overlay-unstable
          neovim-nightly-overlay.overlay
          emacs-overlay.overlay
        ];
      };
      lib = nixpkgs.lib;
      homeManagerImports = [
        ./users/jack/home.nix
        ./users/jack/fish.nix
        ./users/jack/sway
        ./users/jack/neovim
        ./users/jack/emacs
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
          inherit system pkgs;
          modules = [
            nixos-hardware.nixosModules.lenovo-thinkpad-x1-6th-gen
            ./hosts/tui
            ./features/fonts.nix
            ./features/games.nix
            ./features/sway-desktop.nix
            ./features/key-remapping.nix
          ];
        };

        kakapo = lib.nixosSystem {
          inherit system pkgs;
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
