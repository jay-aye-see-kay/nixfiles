{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    home-manager.url = "github:nix-community/home-manager/release-21.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, home-manager, sops-nix }:
    let
      username = "jack";
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };
      lib = nixpkgs.lib;
    in
    {
      homeManagerConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit system pkgs username;
        homeDirectory = "/home/jack";
        configuration.imports = [
          ./users/jack/home.nix
        ];
      };

      nixosConfigurations = {
        kakapo = lib.nixosSystem {
          inherit system;
          modules = [
            sops-nix.nixosModules.sops
            ./secrets/sops.nix
            ./systems/kakapo
            # ./web-services
          ];
        };

      };
    };
}
