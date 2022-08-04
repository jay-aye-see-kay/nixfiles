{ config, pkgs, lib, ... }:
let
  fern-hijack = pkgs.vimUtils.buildVimPlugin {
    name = "fern-hijack";
    src = pkgs.fetchFromGitHub {
      owner = "lambdalisue";
      repo = "fern-hijack.vim";
      rev = "5989a1ac6ddffd0fe49631826b6743b129992b32";
      sha256 = "zvTTdkyywBl0U3DdZnzIXunFTZR9eRL3fJFWjAbb7JI=";
    };
  };
  fern-git-status = pkgs.vimUtils.buildVimPlugin {
    name = "fern-git-status";
    src = pkgs.fetchFromGitHub {
      owner = "lambdalisue";
      repo = "fern-git-status.vim";
      rev = "151336335d3b6975153dad77e60049ca7111da8e";
      sha256 = "9N+T/MB+4hKcxoKRwY8F7iwmTsMtNmHCHiVZfcsADcc=";
    };
  };
  fern-renderer-nerdfont = pkgs.vimUtils.buildVimPlugin {
    name = "fern-renderer-nerdfont";
    src = pkgs.fetchFromGitHub {
      owner = "lambdalisue";
      repo = "fern-renderer-nerdfont.vim";
      rev = "1a3719f226edc27e7241da7cda4bc4d4c7db889c";
      sha256 = "sha256-rWsTB5GkCPqicP6zRoJWnwBUAPDklGny/vjeRu2e0YY=";
    };
  };
  nerdfont = pkgs.vimUtils.buildVimPlugin {
    name = "nerdfont";
    src = pkgs.fetchFromGitHub {
      owner = "lambdalisue";
      repo = "nerdfont.vim";
      rev = "b7dec1f9798470abf9ef877d01e4415d72f792be";
      sha256 = "NYonYP54PVUwHbU+Q/D7MqhVh+IB0B17KaHtkg19PaI=";
    };
  };
  bullets-vim = pkgs.vimUtils.buildVimPlugin {
    name = "bullets";
    src = pkgs.fetchFromGitHub {
      owner = "dkarter";
      repo = "bullets.vim";
      rev = "f3b4ae71f60b5723077a77cfe9e8776a3ca553ac";
      sha256 = "OqVGuf/imrSvj6OFkQw7VmSZ/69WdBx3YBLLv2vrz7U=";
    };
  };
  vim-symlink = pkgs.vimUtils.buildVimPlugin {
    name = "vim-symlink";
    buildPhase = ":";
    configurePhase = ":";
    src = pkgs.fetchFromGitHub {
      owner = "aymericbeaumet";
      repo = "vim-symlink";
      rev = "65218090bfb038488aec1f75cbb6dfe6970077d1";
      sha256 = "ZNM7wYbJTHX6m+J2hcHtGptTsN0SlkWy5EQqwBDgzf4=";
    };
  };
  vim-resize-mode = pkgs.vimUtils.buildVimPlugin {
    name = "vim-resize-mode";
    src = pkgs.fetchFromGitHub {
      owner = "sedm0784";
      repo = "vim-resize-mode";
      rev = "555759fbbd0b7096da1cf6e7bf29acf850423f94";
      sha256 = "drQG1ObxR4HHsNnEEBtvZQVPrsjZuHt57PTHOSkNMSs=";
    };
  };
in {
  programs.neovim = {
    enable = true;
    withNodeJs = true;

    extraConfig = ''
      set termguicolors
      ${pkgs.lib.readFile ./file-tree.vim}
      ${pkgs.lib.readFile ./functions.vim}
      ${pkgs.lib.readFile ./terminal.vim}

      lua << EOF
      ${pkgs.lib.readFile ./init.lua}
      EOF
    '';

    plugins = with pkgs.vimPlugins; [
      {
        plugin = nvcode-color-schemes-vim;
        config = "colorscheme nvcode";
      }

      # langs
      vim-nix
      vim-json
      jsonc-vim

      (nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars))
      nvim-treesitter-textobjects
      nvim-ts-autotag
      playground # tree-sitter playground

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

      orgmode
      friendly-snippets
      neoformat
      tabular
      nvim-ts-context-commentstring
      lightline-vim
      lightline-lsp
      nvim-web-devicons
      vim-bbye
      plenary-nvim
      popup-nvim
      trouble-nvim
      symbols-outline-nvim
      fern-vim
      fern-hijack
      fern-git-status
      fern-renderer-nerdfont
      nerdfont
      bullets-vim
      vim-symlink
      vim-resize-mode

      telescope-nvim
      telescope-fzf-native-nvim
      telescope-symbols-nvim
      fzf-vim
      nvim-fzf

      nvim-colorizer-lua
      hop-nvim
      vim-mundo
      vim-lastplace
      which-key-nvim
      lua-dev-nvim
      dressing-nvim
      {
        plugin = fidget-nvim;
        config = "lua require('fidget').setup()";
      }

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
      {
        plugin = gitsigns-nvim;
        config = "lua require('gitsigns').setup()";
      }
      vim-fugitive
      vim-rhubarb

      {
        plugin = pkgs.unstable.vimPlugins.copilot-vim;
        config = ''
          lua vim.g.copilot_node_command = "${pkgs.nodejs}/bin/node"
          lua vim.g.copilot_no_tab_map = true
          lua vim.g.copilot_enabled = false
        '';
      }

      /* TODO:
         "dkarter/bullets.vim",
         use({ "rafcamlet/nvim-luapad", cmd = { "Luapad", "LuaRun" } })
         "ibhagwan/fzf-lua",
         "monaqa/dial.nvim",
      */
    ];

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
  };
}
