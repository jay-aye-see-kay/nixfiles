{ lib, pkgs, ... }:
{
  programs.emacs = {
    enable = true;
    # extraConfig = lib.readFile ./emacs.el;
    extraPackages = epkgs: with epkgs; [
      all-the-icons
      company
      company-box
      dashboard
      devdocs
      evil
      evil-collection
      evil-numbers
      evil-org
      evil-surround
      general
      helpful
      hydra
      lsp-mode
      lsp-ui
      magit
      nix-mode
      no-littering
      orderless
      # org-modern
      origami
      projectile
      restclient
      tree-sitter
      tree-sitter-langs
      typescript-mode
      undo-tree
      use-package
      vertico
      vterm
      which-key
    ];
  };

  # just install language servers globally
  home.packages = with pkgs.unstable; [
    rnix-lsp
    nodePackages.typescript
    nodePackages.typescript-language-server
  ];
}
