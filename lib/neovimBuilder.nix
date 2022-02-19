{ pkgs, lib ? pkgs.lib, ... }:

{ customRC ? "",
  viAlias  ? true,
  vimAlias ? true,
  start    ? [],
  opt      ? [],
  debug    ? false }:
let
  neovimPlugins = pkgs.neovimPlugins;
  myNeovimUnwrapped = pkgs.neovim-unwrapped.overrideAttrs (prev: {
    propagatedBuildInputs = with pkgs; [ pkgs.stdenv.cc.cc.lib ];
  });
in
pkgs.wrapNeovim myNeovimUnwrapped {
  inherit viAlias;
  inherit vimAlias;
  configure = {
    customRC = customRC;
    packages.myVimPackage = with neovimPlugins; {
      start = builtins.attrNames neovimPlugins;
      opt = opt;
    };
  };
}
