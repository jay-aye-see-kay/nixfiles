{ lib, pkgs, ... }:
let
  ifLinux = lib.mkIf pkgs.stdenv.isLinux;
  emacsPkg = (pkgs.emacsWithPackagesFromUsePackage {
    config = ./init.el;
    package = pkgs.emacs28NativeComp;
    alwaysEnsure = true;
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

  # put tsx grammar somewhere where emacs can find it
  home.file.".tree-sitter/bin/tsx.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-tsx}/parser";

  # install language servers globally
  home.packages = with pkgs; [
    shellcheck
    rnix-lsp
    nixfmt
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.mermaid-cli
    texlive.combined.scheme-medium
  ];
}
