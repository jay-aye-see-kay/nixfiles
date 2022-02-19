{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils = {
      #inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/flake-utils";
    };
    neovim-flake = {
      url = "github:neovim/neovim?dir=contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Theme
    "plugin:vim-moonfly-colors" = {
      url = "github:bluz71/vim-moonfly-colors";
      flake = false;
    };
    # Git
    "plugin:gitsigns" = {
      url = "github:lewis6991/gitsigns.nvim";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pluginOverlay = final: prev:
        let
          inherit (prev.vimUtils) buildVimPluginFrom2Nix;

          treesitterGrammars = prev.tree-sitter.withPlugins (_: prev.tree-sitter.allGrammars);

          plugins = builtins.filter (s: (builtins.match "plugin:.*" s) != null) (builtins.attrNames inputs);
          plugName = input:
            builtins.substring
              (builtins.stringLength "plugin:")
              (builtins.stringLength input)
              input;

          buildPlug = name: buildVimPluginFrom2Nix {
            pname = plugName name;
            version = "master";
            src = builtins.getAttr name inputs;

            # Tree-sitter fails for a variety of lang grammars unless using :TSUpdate
            # For now install imperatively
            #postPatch =
            #  if (name == "nvim-treesitter") then ''
            #    rm -r parser
            #    ln -s ${treesitterGrammars} parser
            #  '' else "";
          };
        in
        {
          neovimPlugins = builtins.listToAttrs (map
            (plugin: {
              name = plugName plugin;
              value = buildPlug plugin;
            })
            plugins);
        };

        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            pluginOverlay
            (final: prev: {
              neovim-unwrapped = inputs.neovim-flake.packages.${prev.system}.neovim;
            })
          ];
        };

        neovimBuilder = { customRC ? ""
                        , viAlias  ? true
                        , vimAlias ? true
                        , start    ? []
                        ,opt      ? []
                        ,debug    ? false }:
                        let
                          neovimPlugins = pkgs.neovimPlugins;
                          myNeovimUnwrapped = pkgs.neovim-unwrapped.overrideAttrs (prev: {
                            propagatedBuildInputs = with pkgs; [ pkgs.stdenv.cc.cc.lib ];
                          });
                        in
                        pkgs.wrapNeovim myNeovimUnwrapped {
                          inherit viAlias;
                          inherit vimAlias;
                          configure = {
                            customRC = customRC;
                            packages.myVimPackage = with neovimPlugins; {
                              start = builtins.attrNames neovimPlugins;
                              opt = opt;
                            };
                          };
                        };
      in
      rec {
        apps = {
          nvim = {
            type = "app";
            program = "${defaultPackage}/bin/nvim";
          };
        };

        defaultApp = apps.nvim;
        defaultPackage = packages.neovimLuca;

        overlay = (self: super: {
          inherit neovimBuilder;
          neovimTraxys = packages.neovimTraxys;
          neovimPlugins = pkgs.neovimPlugins;
        });

        packages.neovimLuca = neovimBuilder {
          start = ["gitsigns"];
        };
      }
    );
}
