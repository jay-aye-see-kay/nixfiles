{ config, pkgs, ... }:
{
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

    plugins = with pkgs.unstable.vimPlugins; [
      { plugin = nvcode-color-schemes-vim; config = "colorscheme nvcode"; }

      # langs
      vim-nix
      vim-json
      jsonc-vim

      nvim-treesitter
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
      fidget-nvim

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
      gitsigns-nvim
      vim-fugitive
      vim-rhubarb

      /* TODO:
        "dkarter/bullets.vim",
        "lambdalisue/fern-git-status.vim",
        "lambdalisue/fern-hijack.vim",
        "lambdalisue/fern-renderer-nerdfont.vim",
        "lambdalisue/nerdfont.vim",
        use({ "aymericbeaumet/vim-symlink" })
        use({ "rafcamlet/nvim-luapad", cmd = { "Luapad", "LuaRun" } })
        use({ "sedm0784/vim-resize-mode" })
        "ibhagwan/fzf-lua",
        "monaqa/dial.nvim",
      */

    ];

    extraPackages = with pkgs.unstable; [
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

      # tree-sitter
      tree-sitter
      tree-sitter-grammars.tree-sitter-bash
      tree-sitter-grammars.tree-sitter-c
      tree-sitter-grammars.tree-sitter-fish
      tree-sitter-grammars.tree-sitter-javascript
      tree-sitter-grammars.tree-sitter-lua
      tree-sitter-grammars.tree-sitter-nix
      tree-sitter-grammars.tree-sitter-org-nvim
      tree-sitter-grammars.tree-sitter-python
      tree-sitter-grammars.tree-sitter-rust
      tree-sitter-grammars.tree-sitter-tsx
      tree-sitter-grammars.tree-sitter-typescript
      tree-sitter-grammars.tree-sitter-vim
    ];
  };

  xdg.configFile = with pkgs.unstable; {
    "nvim/parser/bash.so".source = "${tree-sitter.builtGrammars.tree-sitter-bash}/parser";
    "nvim/parser/c.so".source = "${tree-sitter.builtGrammars.tree-sitter-c}/parser";
    "nvim/parser/fish.so".source = "${tree-sitter.builtGrammars.tree-sitter-fish}/parser";
    "nvim/parser/javascript.so".source = "${tree-sitter.builtGrammars.tree-sitter-javascript}/parser";
    "nvim/parser/lua.so".source = "${tree-sitter.builtGrammars.tree-sitter-lua}/parser";
    "nvim/parser/nix.so".source = "${tree-sitter.builtGrammars.tree-sitter-nix}/parser";
    "nvim/parser/org.so".source = "${tree-sitter.builtGrammars.tree-sitter-org-nvim}/parser";
    "nvim/parser/python.so".source = "${tree-sitter.builtGrammars.tree-sitter-python}/parser";
    "nvim/parser/rust.so".source = "${tree-sitter.builtGrammars.tree-sitter-rust}/parser";
    "nvim/parser/tsx.so".source = "${tree-sitter.builtGrammars.tree-sitter-tsx}/parser";
    "nvim/parser/typescript.so".source = "${tree-sitter.builtGrammars.tree-sitter-typescript}/parser";
    "nvim/parser/vim.so".source = "${tree-sitter.builtGrammars.tree-sitter-vim}/parser";
  };
}
