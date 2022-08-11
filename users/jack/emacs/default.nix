{ lib, pkgs, ... }:
let
  ifLinux = lib.mkIf pkgs.stdenv.isLinux;
  emacsPkg = (pkgs.emacsWithPackagesFromUsePackage {
    config = ./init.el;
    package = pkgs.emacs28NativeComp;
    alwaysEnsure = true;
    override = epkgs:
      epkgs // import ./package-overrides.nix {
        epkgs = epkgs;
        pkgs = pkgs;
      };
  });
in {
  home.file.".emacs.d/init.el".source = ./init.el;

  programs.emacs = {
    enable = true;
    package = emacsPkg;
  };

  services.emacs = ifLinux {
    enable = true;
    client.enable = true;
    defaultEditor = true;
    package = emacsPkg;
  };

  # put extra TS grammars somewhere where emacs can find them
  home.file.".tree-sitter/bin/fish.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-fish}/parser";
  home.file.".tree-sitter/bin/graphql.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-graphql}/parser";
  home.file.".tree-sitter/bin/prisma.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-prisma}/parser";
  home.file.".tree-sitter/bin/tsx.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-tsx}/parser";
  home.file.".tree-sitter/bin/vim.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-vim}/parser";
  home.file.".tree-sitter/bin/yaml.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-yaml}/parser";

  # install language servers globally
  home.packages = with pkgs; [
    emacs-all-the-icons-fonts
    shellcheck
    nixpkgs-fmt
    nodePackages.mermaid-cli
    texlive.combined.scheme-medium

    # language servers
    nodePackages."@prisma/language-server"
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
