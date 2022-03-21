{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    sops-nix.url = github:Mic92/sops-nix;
  };

  outputs = { self, nixpkgs, sops-nix }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };
      lib = nixpkgs.lib;
    in
    {
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
