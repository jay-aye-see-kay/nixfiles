{
  description = "A configured Neovim flake";

  # TODO maybe use makeNeovimConfig from https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/neovim/utils.nix

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Plugins direct from their repos
    "plugin:vim-resize-mode" = {
      url = "github:sedm0784/vim-resize-mode";
      flake = false;
    };
    "plugin:vim-symlink" = {
      url = "github:aymericbeaumet/vim-symlink";
      flake = false;
    };
    "plugin:neo-tree" = {
      url = "github:nvim-neo-tree/neo-tree.nvim";
      flake = false;
    };
    "plugin:nui" = {
      url = "github:MunifTanjim/nui.nvim";
      flake = false;
    };
    "plugin:mkdnflow" = {
      url = "github:jakewvincent/mkdnflow.nvim";
      flake = false;
    };
    "plugin:debugprint" = {
      url = "github:andrewferrier/debugprint.nvim";
      flake = false;
    };
    "plugin:nvim-window-picker" = {
      url = "github:s1n7ax/nvim-window-picker";
      flake = false;
    };
    "plugin:nvim-scrollbar" = {
      url = "github:petertriho/nvim-scrollbar";
      flake = false;
    };
    "plugin:gitsigns" = {
      url = "github:lewis6991/gitsigns.nvim";
      flake = false;
    };
    "plugin:nvim-unception" = {
      url = "github:samjwill/nvim-unception";
      flake = false;
    };
    "plugin:telescope-manix" = {
      url = "github:MrcJkb/telescope-manix";
      flake = false;
    };
    "plugin:refactoring-nvim" = {
      url = "github:ThePrimeagen/refactoring.nvim";
      flake = false;
    };
    "plugin:vim-just" = {
      url = "github:NoahTheDuke/vim-just";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Once we add this overlay to our nixpkgs, we are able to
        # use `pkgs.neovimPlugins`, which is a map of our plugins.
        # Each input in the format:
        # ```
        # "plugin:yourPluginName" = {
        #   url   = "github:exampleAuthor/examplePlugin";
        #   flake = false;
        # };
        # ```
        # included in the `inputs` section is packaged to a (neo-)vim
        # plugin and can then be used via
        # ```
        # pkgs.neovimPlugins.yourPluginName
        # ```
        pluginOverlay = final: prev:
          let
            inherit (prev.vimUtils) buildVimPluginFrom2Nix;
            plugins = builtins.filter
              (s: (builtins.match "plugin:.*" s) != null)
              (builtins.attrNames inputs);
            plugName = input:
              builtins.substring
                (builtins.stringLength "plugin:")
                (builtins.stringLength input)
                input;
            buildPlug = name: buildVimPluginFrom2Nix {
              pname = plugName name;
              version = "master";
              src = builtins.getAttr name inputs;
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

        # Apply the overlay and load nixpkgs as `pkgs`
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            pluginOverlay
          ];
        };

        # neovimBuilder is a function that takes your prefered
        # configuration as input and just returns a version of
        # neovim where the default config was overwritten with your
        # config.
        # 
        # Parameters:
        # customRC | your init.vim as string
        # viAlias  | allow calling neovim using `vi`
        # vimAlias | allow calling neovim using `vim`
        # start    | The set of plugins to load on every startup
        #          | The list is in the form ["yourPluginName" "anotherPluginYouLike"];
        #          |
        #          | Important: The default is to load all plugins, if
        #          |            `start = [ "blabla" "blablabla" ]` is
        #          |            not passed as an argument to neovimBuilder!
        #          |
        #          | Make sure to add:
        #          | ```
        #          | "plugin:yourPluginName" = {
        #          |   url   = "github:exampleAuthor/examplePlugin";
        #          |   flake = false;
        #          | };
        #          | 
        #          | "plugin:anotherPluginYouLike" = {
        #          |   url   = "github:exampleAuthor/examplePlugin";
        #          |   flake = false;
        #          | };
        #          | ```
        #          | to your imports!
        # opt      | List of optional plugins to load only when 
        #          | explicitly loaded from inside neovim
        neovimBuilder =
          { customRC ? ""
          , viAlias ? true
          , vimAlias ? true
          , start ? builtins.attrValues pkgs.neovimPlugins
          , opt ? [ ]
          , debug ? false
          }:
          let
            myNeovimUnwrapped = pkgs.neovim-unwrapped.overrideAttrs (prev: {
              propagatedBuildInputs = with pkgs; [ pkgs.stdenv.cc.cc.lib ];
            });
          in
          pkgs.wrapNeovim myNeovimUnwrapped {
            inherit viAlias;
            inherit vimAlias;
            configure = {
              customRC = customRC;
              packages.myVimPackage = with pkgs.neovimPlugins; {
                start = start;
                opt = opt;
              };
            };
          };
      in
      rec {
        apps.default = apps.nvim;
        defaultPackage = packages.myNeovim;

        apps.nvim = {
          type = "app";
          program = "${defaultPackage}/bin/nvim";
        };

        packages.myNeovim = neovimBuilder {
          customRC = ''
            lua << EOF
            ${pkgs.lib.readFile ./init.lua}
            EOF
          '';
          start =
            let
              # get all the plugins defined in this file, a fair bit of doing + undoing, could be simplified a lot
              allPluginsFromInputs = (pkgs.lib.attrsets.mapAttrsToList (name: value: value) pkgs.neovimPlugins);
            in
            allPluginsFromInputs ++ (with pkgs.vimPlugins; [
              tokyonight-nvim
              indent-blankline-nvim
              impatient-nvim

              # langs
              vim-nix
              vim-json
              jsonc-vim
              splitjoin-vim

              (nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars))
              nvim-treesitter-textobjects
              nvim-ts-autotag
              playground # tree-sitter playground

              nvim-lspconfig
              nvim-lsp-ts-utils
              lsp_signature-nvim
              SchemaStore-nvim
              nvim-cmp
              cmp-buffer
              cmp-path
              cmp-nvim-lua
              cmp-nvim-lsp
              cmp_luasnip
              lspkind-nvim
              luasnip
              nvim-autopairs

              # contain these, maybe remove
              friendly-snippets
              neoformat

              nvim-web-devicons
              lualine-nvim
              lualine-lsp-progress
              nvim-navic

              markdown-preview-nvim
              tabular
              nvim-ts-context-commentstring
              vim-bbye
              plenary-nvim
              popup-nvim
              trouble-nvim
              symbols-outline-nvim

              telescope-nvim
              telescope-fzf-native-nvim
              telescope-symbols-nvim
              fzf-vim

              nvim-colorizer-lua
              hop-nvim
              vim-mundo
              vim-lastplace
              which-key-nvim
              neodev-nvim
              dressing-nvim

              # tpope
              vim-abolish
              vim-commentary
              vim-repeat
              vim-surround
              vim-unimpaired
              targets-vim

              # git
              git-messenger-vim
              diffview-nvim
              vim-fugitive
              vim-rhubarb
              conflict-marker-vim
            ]);
        };

        overlays.default = final: prev: { neovim = defaultPackage; };

        extraPackages = with pkgs; [
          fzf
          nodejs
          stylua
          # language servers
          nodePackages.bash-language-server
          nodePackages.dockerfile-language-server-nodejs
          nodePackages.pyright
          nodePackages.typescript
          nodePackages.typescript-language-server
          nodePackages.vim-language-server
          nodePackages.vscode-langservers-extracted
          nodePackages.yaml-language-server
          rnix-lsp
          rubyPackages.solargraph
          rust-analyzer
          sumneko-lua-language-server
        ];
      }
    );
}
