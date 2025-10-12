# TEMP: LSPs etc from old nvim flake, should be a module
# don't think I need all of these

{ pkgs, ... }:
{
  environment.systemPackages = with pkgs.unstable; [
    # LSPs and linters
    godef
    gopls
    nodePackages."@tailwindcss/language-server"
    nodePackages.bash-language-server
    dockerfile-language-server
    nodePackages.eslint_d
    pyright
    nodePackages.typescript
    nodePackages.typescript-language-server
    nodePackages.vim-language-server
    nodePackages.vscode-langservers-extracted
    nodePackages.yaml-language-server
    nixd
    rubyPackages.solargraph
    rust-analyzer
    shellcheck
    statix
    sumneko-lua-language-server
    ruff
    terraform-ls
    markdown-oxide

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
  ];
}
