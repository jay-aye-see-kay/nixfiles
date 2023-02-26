{
  description = "A configured Neovim flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Plugins direct from their repos
    "plugin:vim-symlink" = {
      url = "github:aymericbeaumet/vim-symlink";
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
    "plugin:nvim-unception" = {
      url = "github:samjwill/nvim-unception";
      flake = false;
    };
    "plugin:vim-just" = {
      url = "github:NoahTheDuke/vim-just";
      flake = false;
    };
    "plugin:git-conflict-nvim" = {
      url = "github:akinsho/git-conflict.nvim/v1.0.0";
      flake = false;
    };
    "plugin:yop-nvim" = {
      url = "github:zdcthomas/yop.nvim";
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

        allPluginsFromInputs = pkgs.lib.attrsets.mapAttrsToList (name: value: value) pkgs.neovimPlugins;

        customConfig = pkgs.neovimUtils.makeNeovimConfig {
          withNodeJs = true;
          customRC = ''
            lua << EOF
              vim.opt.rtp:prepend("${./config}")
              vim.opt.packpath = vim.opt.rtp:get()
              require("_cfg")
            EOF
          '';
          plugins = allPluginsFromInputs ++ (with pkgs.vimPlugins; [
            { plugin = impatient-nvim; config = "lua require('impatient')"; }

            # dependencies
            plenary-nvim
            popup-nvim
            nui-nvim
            nvim-web-devicons
            dressing-nvim
            vim-repeat

            # colourscheme
            lush-nvim
            zenbones-nvim
            indent-blankline-nvim

            nvim-dap
            nvim-dap-ui
            nvim-dap-virtual-text
            nvim-dap-go

            # langs
            vim-nix
            vim-json
            jsonc-vim

            (nvim-treesitter.withPlugins (_: nvim-treesitter.allGrammars))
            nvim-treesitter-textobjects
            nvim-ts-autotag
            playground # tree-sitter playground

            # comments
            { plugin = comment-nvim; config = "lua require('Comment').setup({ pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook() })"; }
            nvim-ts-context-commentstring

            # lsp stuff
            nvim-lspconfig
            nvim-lsp-ts-utils # TODO replace with https://github.com/leafgarland/typescript-vim
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
            { plugin = goto-preview; config = "lua require('goto-preview').setup({ default_mappings = true })"; }
            null-ls-nvim
            friendly-snippets
            todo-comments-nvim

            lualine-nvim
            lualine-lsp-progress # switch back to fidget?
            nvim-navic
            neo-tree-nvim
            refactoring-nvim

            hydra-nvim
            markdown-preview-nvim
            vim-bbye
            trouble-nvim

            telescope-nvim
            telescope-fzf-native-nvim
            telescope-zoxide
            telescope-undo-nvim

            nvim-colorizer-lua
            vim-mundo
            vim-lastplace
            which-key-nvim
            neodev-nvim

            { plugin = nvim-surround; config = "lua require('nvim-surround').setup()"; }
            mini-nvim
            text-case-nvim

            # git
            diffview-nvim
            vim-fugitive
            vim-rhubarb
            gitsigns-nvim
          ]);
        };

        # Extra packages made available to nvim but not the system
        # system packages take precedence over these
        extraPkgsPath = pkgs.lib.makeBinPath (with pkgs; [
          # LSPs and linters
          godef
          gopls
          nodePackages.bash-language-server
          nodePackages.dockerfile-language-server-nodejs
          nodePackages.eslint_d
          nodePackages.pyright
          nodePackages.typescript
          nodePackages.typescript-language-server
          nodePackages.vim-language-server
          nodePackages.vscode-langservers-extracted
          nodePackages.yaml-language-server
          rnix-lsp
          rubyPackages.solargraph
          rust-analyzer
          shellcheck
          statix
          sumneko-lua-language-server

          # Formatters
          black
          nodePackages.prettier_d_slim
          shfmt
          stylua
          rustfmt

          # Debuggers
          delve

          # Dicts
          aspell
          aspellDicts.en

          # nvim-spectre expects a binary "gsed" on macos
          (pkgs.writeShellScriptBin "gsed" "exec ${pkgs.gnused}/bin/sed")
        ]);
      in
      rec {
        packages.nvim = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped (customConfig // {
          wrapperArgs = customConfig.wrapperArgs ++ [ "--suffix" "PATH" ":" extraPkgsPath ];
        });
        defaultPackage = packages.nvim;
        apps.nvim = { type = "app"; program = "${defaultPackage}/bin/nvim"; };
        apps.default = apps.nvim;
        overlays.default = final: prev: { neovim = defaultPackage; };
      }
    );
}
