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
      lib = nixpkgs.lib;

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
      #       "aarch64-darwn": "__aarch64-darwn";
      #     }
      eachMySystem = (mkConfig: (lib.lists.fold
        (system: accum: accum // { ${system} = mkConfig system; })
        { }
        mySystems));

      # Build pkgs with all my overlays for a given system
      mkPkgs = system:
        let
          nixpkgs-unstable-overlay = final: prev: {
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
            nixpkgs-unstable-overlay
            emacs-overlay.overlay
            nodePkgsOverlay
            neovim-flake.overlays.${system}.default
          ];
        };

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
      formatter = eachMySystem (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      homeManagerConfigurations.${username} = eachMySystem (system:
        home-manager.lib.homeManagerConfiguration {
          inherit system username;
          pkgs = mkPkgs system;
          homeDirectory = "/home/${username}";
          configuration.imports = linuxHomeManagerImports;
          extraSpecialArgs = {
            # WIP not using this, but it's cool I can pass it through
            jdr.neovim-packages = neovim-flake.extraPackages.${system};
          };
        }
      );

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
