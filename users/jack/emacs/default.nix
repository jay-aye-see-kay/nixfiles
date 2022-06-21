{ lib, pkgs, ... }:
{
  programs.emacs = {
    enable = true;
    # extraConfig = lib.readFile ./emacs.el;
    extraPackages = epkgs: with epkgs; [
      all-the-icons
      avy
      company
      company-box
      dashboard
      deadgrep
      devdocs
      doom-modeline
      evil
      evil-collection
      evil-commentary
      evil-goggles
      evil-numbers
      evil-org
      evil-surround
      general
      helpful
      hydra
      lsp-mode
      lsp-ui
      magit
      marginalia
      nix-mode
      no-littering
      orderless
      org-modern
      origami
      projectile
      restclient
      tree-sitter
      tree-sitter-langs
      typescript-mode
      undo-tree
      use-package
      vertico
      visual-fill-column
      vterm
      which-key
    ];
  };

  # just install language servers globally
  home.packages = with pkgs; [
    rnix-lsp
    nodePackages.typescript
    nodePackages.typescript-language-server
  ];
}
