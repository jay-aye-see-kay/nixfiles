{
  description = "A configured Neovim flake";

  inputs = {
    nixpkgs.url = "github:jay-aye-see-kay/nixpkgs/add-aerospace";
    flake-utils.url = "github:numtide/flake-utils";

    # Plugins direct from their repos
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
        makeNeovim = import ./makeNeovim.nix { inherit pkgs; };

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

        mainNeovimArgs = {
          extraPython3Packages = p: [ p.debugpy ];

          lazyPlugins = allPluginsFromInputs ++ (with pkgs.vimPlugins; [
            catppuccin-nvim
            nvim-unception

            mini-nvim
            leap-nvim

            # dependencies
            plenary-nvim
            popup-nvim
            nui-nvim
            nvim-web-devicons
            dressing-nvim
            vim-repeat

            nvim-dap
            nvim-dap-ui
            nvim-nio
            nvim-dap-virtual-text
            nvim-dap-go
            nvim-dap-python
            debugprint-nvim

            # langs
            vim-caddyfile
            typescript-nvim

            nvim-treesitter
            nvim-treesitter-textobjects
            nvim-ts-autotag

            # comments
            comment-nvim
            nvim-ts-context-commentstring

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
            null-ls-nvim
            friendly-snippets
            mkdnflow-nvim
            hover-nvim
            outline-nvim

            lualine-nvim
            lualine-lsp-progress # switch back to fidget?
            nvim-navic
            neo-tree-nvim
            oil-nvim
            refactoring-nvim

            hydra-nvim
            markdown-preview-nvim
            trouble-nvim

            telescope-nvim
            telescope-fzf-native-nvim
            telescope-zoxide
            telescope-undo-nvim
            telescope-live-grep-args-nvim

            nvim-colorizer-lua
            undotree
            which-key-nvim
            neodev-nvim

            nvim-surround
            text-case-nvim

            # git
            diffview-nvim
            vim-fugitive
            vim-rhubarb
            gitsigns-nvim
            git-conflict-nvim
          ]);

          extraPackages = with pkgs; [
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
          ];
        };

        #
        # the actual neovim packages
        #
        mainNeovim = makeNeovim mainNeovimArgs;
        smallNeovim = makeNeovim mainNeovimArgs; # TODO: a smaller build for servers, take out LSPs and debuggers

        # identical to above pkgs, but with NVIM_APPNAME set so cache/state files are isolated
        mainNeovimDev = makeNeovim (mainNeovimArgs // { nvimAppName = "nvim-dev"; });
        smallNeovimDev = makeNeovim (mainNeovimArgs // { nvimAppName = "nvim-dev-small"; });
      in
      {
        packages = {
          inherit mainNeovim smallNeovim;
        };

        overlays.default = _: _: {
          inherit mainNeovim smallNeovim;
        };

        packages.default = mainNeovimDev; # I only ever run `nix build. #` when trying new things
        apps.smallNeovim = { type = "app"; program = "${smallNeovimDev}/bin/nvim"; };
        apps.default = { type = "app"; program = "${mainNeovimDev}/bin/nvim"; };
      }
    );
}
