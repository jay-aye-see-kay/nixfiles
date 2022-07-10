{ lib, pkgs, ... }: {
  services.emacs.enable = true;
  programs.emacs = {
    enable = true;
    package = pkgs.emacs28NativeComp;
    # extraConfig = lib.readFile ./emacs.el;
    extraPackages = epkgs:
      with epkgs; [
        all-the-icons
        apheleia
        avy
        company
        company-box
        consult
        dashboard
        deadgrep
        devdocs
        doom-modeline
        embark
        evil
        evil-collection
        evil-commentary
        evil-goggles
        evil-numbers
        evil-org
        evil-surround
        evil-textobj-tree-sitter
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
        org
        origami
        plantuml-mode
        quelpa
        quelpa-use-package
        restclient
        tree-sitter
        tree-sitter-langs
        treemacs
        treemacs-evil
        typescript-mode
        undo-tree
        use-package
        vertico
        visual-fill-column
        vterm
        vundo
        which-key
        yasnippet
      ];
  };

  # just install language servers globally
  home.packages = with pkgs; [
    rnix-lsp
    nixfmt
    nodePackages.typescript
    nodePackages.typescript-language-server
    tree-sitter-grammars.tree-sitter-tsx
    nodePackages.mermaid-cli
    texlive.combined.scheme-medium
  ];
}
