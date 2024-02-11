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
    "plugin:debugprint" = {
      url = "github:andrewferrier/debugprint.nvim";
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
    "plugin:typescript-nvim" = {
      url = "github:jose-elias-alvarez/typescript.nvim";
      flake = false;
    };
    "plugin:mini-nvim" = {
      url = "github:echasnovski/mini.nvim";
      flake = false;
    };
    "plugin:advanced-git-search-nvim" = {
      url = "github:aaronhallaert/advanced-git-search.nvim";
      flake = false;
    };
    "plugin:tsnode-marker-nvim" = {
      url = "github:atusy/tsnode-marker.nvim";
      flake = false;
    };
    "plugin:gp-nvim" = {
      url = "github:Robitx/gp.nvim";
      flake = false;
    };
    "plugin:bats-nvim" = {
      url = "github:aliou/bats.vim";
      flake = false;
    };
    "plugin:vim-jinja2-syntax" = {
      url = "github:Glench/Vim-Jinja2-Syntax";
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
            inherit (prev.vimUtils) buildVimPlugin;
            plugins = builtins.filter
              (s: (builtins.match "plugin:.*" s) != null)
              (builtins.attrNames inputs);
            plugName = input:
              builtins.substring
                (builtins.stringLength "plugin:")
                (builtins.stringLength input)
                input;
            buildPlug = name: buildVimPlugin {
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
          config.allowUnfree = true;
          overlays = [
            pluginOverlay
          ];
        };

        allPluginsFromInputs = pkgs.lib.attrsets.mapAttrsToList (name: value: value) pkgs.neovimPlugins;

        customConfig = pkgs.neovimUtils.makeNeovimConfig {
          withPython3 = true;
          extraPython3Packages = p: [ p.debugpy ];
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
            catppuccin-nvim
            nvim-unception

            # dependencies
            plenary-nvim
            popup-nvim
            nui-nvim
            nvim-web-devicons
            dressing-nvim
            vim-repeat

            nvim-dap
            nvim-dap-ui
            nvim-dap-virtual-text
            nvim-dap-go
            nvim-dap-python

            # langs
            vim-nix
            vim-json
            jsonc-vim
            vim-caddyfile
            vim-just

            (nvim-treesitter.withPlugins (_: nvim-treesitter.allGrammars ++ [
              (pkgs.tree-sitter.buildGrammar {
                language = "just";
                version = "8af0aab";
                src = pkgs.fetchFromGitHub {
                  owner = "IndianBoy42";
                  repo = "tree-sitter-just";
                  rev = "8af0aab79854aaf25b620a52c39485849922f766";
                  sha256 = "sha256-hYKFidN3LHJg2NLM1EiJFki+0nqi1URnoLLPknUbFJY=";
                };
              })
            ]))
            nvim-treesitter-textobjects
            nvim-ts-autotag
            playground # tree-sitter playground

            # comments
            { plugin = comment-nvim; config = "lua require('Comment').setup()"; }
            { plugin = nvim-ts-context-commentstring; config = "lua vim.g.skip_ts_context_commentstring_module = true"; }

            # lsp stuff
            nvim-lspconfig
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
            mkdnflow-nvim
            hover-nvim

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
            telescope-live-grep-args-nvim

            nvim-colorizer-lua
            vim-mundo
            which-key-nvim
            neodev-nvim

            { plugin = nvim-surround; config = "lua require('nvim-surround').setup()"; }
            text-case-nvim

            # git
            diffview-nvim
            vim-fugitive
            vim-rhubarb
            gitsigns-nvim
            neogit
          ]);
        };

        # Extra packages made available to nvim but not the system
        # system packages take precedence over these
        extraPkgsPath = pkgs.lib.makeBinPath (with pkgs; [
          # LSPs and linters
          godef
          gopls
          nodePackages."@tailwindcss/language-server"
          nodePackages.bash-language-server
          nodePackages.dockerfile-language-server-nodejs
          nodePackages.eslint_d
          nodePackages.pyright
          nodePackages.typescript
          nodePackages.typescript-language-server
          nodePackages.vim-language-server
          nodePackages.vscode-langservers-extracted
          nodePackages.yaml-language-server
          nil # nix lsp
          rubyPackages.solargraph
          rust-analyzer
          shellcheck
          statix
          sumneko-lua-language-server
          ruff
          terraform-ls

          # Formatters
          black
          isort
          shfmt
          stylua
          nixpkgs-fmt

          # Debuggers
          delve

          # Dicts
          aspell
          aspellDicts.en

          # nvim-spectre expects a binary "gsed" on macos
          (pkgs.writeShellScriptBin "gsed" "exec ${pkgs.gnused}/bin/sed")
          sox # audio handling for gp.nvim
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
