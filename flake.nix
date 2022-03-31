{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    home-manager.url = "github:nix-community/home-manager/release-21.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable"; 
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, nixpkgs-unstable, neovim-nightly-overlay }:
    let
      username = "jack";
      system = "x86_64-linux";
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
      lib = nixpkgs.lib;
    in
    {
      homeManagerConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit system pkgs username;
        homeDirectory = "/home/jack";
        configuration.imports = [
          ./users/jack/home.nix
          ./users/jack/neovim
        ];
      };

      nixosConfigurations = {
        kakapo = lib.nixosSystem {
          inherit system;
          modules = [
            sops-nix.nixosModules.sops
            ./secrets/sops.nix
            ./systems/kakapo
            ./web-services
          ];
        };

      };
    };
}
