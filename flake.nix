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
    "plugin:nvim-window-picker" = {
      url = "github:s1n7ax/nvim-window-picker";
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
    "plugin:nvim-various-textobjs" = {
      url = "github:chrisgrieser/nvim-various-textobjs";
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

            lush-nvim
            zenbones-nvim
            indent-blankline-nvim

            nvim-dap
            nvim-dap-go
            nvim-dap-ui
            nvim-dap-virtual-text

            # langs
            vim-nix
            vim-json
            jsonc-vim
            splitjoin-vim

            (nvim-treesitter.withPlugins (_: nvim-treesitter.allGrammars))
            nvim-treesitter-textobjects
            nvim-ts-autotag
            playground # tree-sitter playground

            # lsp stuff
            nvim-lspconfig
            nvim-lsp-ts-utils
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
            lsp_lines-nvim
            { plugin = goto-preview; config = "lua require('goto-preview').setup({ default_mappings = true })"; }
            null-ls-nvim
            friendly-snippets
            todo-comments-nvim

            nvim-web-devicons
            lualine-nvim
            lualine-lsp-progress
            nvim-navic
            neo-tree-nvim
            nui-nvim
            gitsigns-nvim
            refactoring-nvim

            hydra-nvim
            markdown-preview-nvim
            tabular
            nvim-ts-context-commentstring
            vim-bbye
            plenary-nvim
            popup-nvim
            trouble-nvim
            symbols-outline-nvim
            nvim-spectre

            telescope-nvim
            telescope-fzf-native-nvim
            telescope-symbols-nvim
            telescope-zoxide
            telescope-undo-nvim
            fzf-vim

            nvim-colorizer-lua
            vim-mundo
            vim-lastplace
            which-key-nvim
            neodev-nvim
            dressing-nvim

            # tpope
            vim-abolish
            vim-commentary
            vim-repeat
            vim-unimpaired

            nvim-surround
            {
              plugin = targets-vim;
              # restore `b` to default vim behaviour, see: https://github.com/wellle/targets.vim#targetsmappingsextend
              config = "autocmd User targets#mappings#user call targets#mappings#extend({ 'b': {'pair': [{'o':'(', 'c':')'}]} })";
            }

            # git
            diffview-nvim
            vim-fugitive
            vim-rhubarb
            octo-nvim
          ]);
        };

        # Extra packages made available to nvim but not the system
        # system packages take precedence over these
        extraPkgsPath = pkgs.lib.makeBinPath (with pkgs; [
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
          stylua
          sumneko-lua-language-server
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
