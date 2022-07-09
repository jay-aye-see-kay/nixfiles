{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };
  outputs = { self, nixpkgs, neovim-nightly-overlay }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [ neovim-nightly-overlay.overlay ];
      };
      myNeovimUnwrapped = pkgs.neovim-unwrapped.overrideAttrs (prev: {
        propagatedBuildInputs = with pkgs; [ pkgs.stdenv.cc.cc.lib ];
      });
      myNeovim = pkgs.wrapNeovim myNeovimUnwrapped {
        configure = { customRC = pkgs.lib.readFile ./init.vim; };
      };
    in rec {
      apps.x86_64-linux.default = {
        type = "app";
        program = "${myNeovim}/bin/nvim";
      };
      overlays.default = final: prev: { myNeovim = myNeovim; };
    };
}
