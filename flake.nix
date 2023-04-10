{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager/release-22.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    neovim-flake.url = "github:jay-aye-see-kay/neovim-flake";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, sops-nix, ... }@inputs:
    let
      inherit (nixpkgs) lib;
      inherit ((import ./utils.nix inputs)) mkPkgs eachMySystem mkHmConfigMod;
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
      homeConfigurations."${username}@moa" = mkHmConfig rec {
        pkgs = mkPkgs "aarch64-linux";
        modules =
          (mkHmConfigMod { inherit username; })
          ++ [ ./users/jack/i3 ];
      };
      nixosCofigurations.moa = let system = "aarch64-linux"; in
        lib.nixosSystem {
          inherit system;
          pkgs = mkPkgs system;
          modules = [ ./hosts/moa ./features/fonts.nix ];
        };

      # home laptop
      homeConfigurations."${username}@tui" = mkHmConfig rec {
        pkgs = mkPkgs "x86_64-linux";
        modules =
          (mkHmConfigMod { inherit username; })
          ++ [ ./users/jack/i3 ];
      };
      nixosConfigurations.tui = let system = "x86_64-linux"; in
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

      # home server
      homeConfigurations."${username}@kakapo" = mkHmConfig rec {
        pkgs = mkPkgs "x86_64-linux";
        modules = mkHmConfigMod { inherit username; };
      };
      homeConfigurations."hud@kakapo" = mkHmConfig rec {
        pkgs = mkPkgs "x86_64-linux";
        modules = mkHmConfigMod { username = "hud"; };
      };
      nixosConfigurations.kakapo = let system = "x86_64-linux"; in
        lib.nixosSystem {
          inherit system;
          pkgs = mkPkgs system;
          modules = [
            sops-nix.nixosModules.sops
            ./secrets/sops.nix
            ./hosts/kakapo
          ];
        };

      # small arm server on aws for file sync
      nixosConfigurations.pukeko = let system = "aarch64-linux"; in
        lib.nixosSystem {
          inherit system;
          pkgs = mkPkgs system;
          modules = [
            ./hosts/pukeko
          ];
        };

    };
}
