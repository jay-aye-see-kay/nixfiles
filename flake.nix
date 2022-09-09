{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager.url = "github:nix-community/home-manager/release-22.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    emacs-overlay.url = "github:nix-community/emacs-overlay";

    neovim-flake.url = "github:jay-aye-see-kay/neovim-flake";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , nixos-hardware
    , home-manager
    , sops-nix
    , emacs-overlay
    , neovim-flake
    }:
    let
      username = "jack";

      mkPkgs = system:
        let
          overlayUnstable = final: prev: {
            unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
          };
          nodePkgsOverlay = final: prev: {
            customNodePackages = import ./node-packages/default.nix { pkgs = prev; };
          };
        in
        import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
          overlays = [
            overlayUnstable
            emacs-overlay.overlay
            nodePkgsOverlay
            neovim-flake.overlays.${system}.default
          ];
        };

      lib = nixpkgs.lib;
      commonHomeManagerImports = [
        ./users/jack/home.nix
        ./users/jack/fish.nix
        ./users/jack/emacs
      ];
      linuxHomeManagerImports = commonHomeManagerImports ++ [ ./users/jack/i3 ];
      darwinHomeManagerImports = commonHomeManagerImports
        ++ [ ./users/jack/fish-macos-fix.nix ];
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;
      formatter.x86_64-darwin = nixpkgs.legacyPackages.x86_64-darwin.nixpkgs-fmt;
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixpkgs-fmt;

      homeManagerConfigurations.${username} =
        let system = "x86_64-linux"; in
        home-manager.lib.homeManagerConfiguration {
          inherit system username;
          pkgs = mkPkgs system;
          homeDirectory = "/home/${username}";
          configuration.imports = linuxHomeManagerImports;
          extraSpecialArgs = {
            # WIP not using this, but it's cool I can pass it through
            jdr.neovim-packages = neovim-flake.extraPackages.${system};
          };
        };

      homeManagerConfigurations."${username}-aarch64" =
        let system = "aarch64-linux"; in
        home-manager.lib.homeManagerConfiguration {
          inherit system username;
          pkgs = mkPkgs system;
          homeDirectory = "/home/${username}";
          configuration.imports = linuxHomeManagerImports;
        };

      homeManagerConfigurations."${username}-mbp" =
        let system = "aarch64-darwin"; in
        home-manager.lib.homeManagerConfiguration {
          inherit system username;
          pkgs = mkPkgs system;
          homeDirectory = "/Users/${username}";
          configuration.imports = darwinHomeManagerImports;
        };

      nixosConfigurations = {
        tui = let system = "x86_64-linux"; in
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

        kakapo = let system = "x86_64-linux"; in
          lib.nixosSystem {
            inherit system;
            pkgs = mkPkgs system;
            modules = [
              sops-nix.nixosModules.sops
              ./secrets/sops.nix
              ./hosts/kakapo
              ./web-services
            ];
          };

        moa = let system = "aarch64-linux"; in
          lib.nixosSystem {
            inherit system;
            pkgs = mkPkgs system;
            modules = [ ./hosts/moa ./features/fonts.nix ];
          };

      };
    };
}
