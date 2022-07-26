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
  home.file.".emacs.d/templates.el".source = ./templates.el;

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

  # install language servers globally
  home.packages = with pkgs; [
    shellcheck
    rnix-lsp
    nixfmt
    nodePackages.typescript
    nodePackages.typescript-language-server
    tree-sitter-grammars.tree-sitter-tsx
    nodePackages.mermaid-cli
    texlive.combined.scheme-medium
  ];
}
