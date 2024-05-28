# Copyright (c) 2023 BirdeeHub
# Licensed under the MIT license

{ pkgs, ... }: with builtins; rec {
  # source: https://github.com/BirdeeHub/nixCats-nvim/blob/cd836e5/nix/utils/default.nix#L164-L184
  luaTablePrinter = attrSet:
    let
      luatableformatter = attrSet:
        let
          nameandstringmap = mapAttrs
            (n: value:
              let
                name = ''[ [[${n}]] ]'';
              in
              if value == true then "${name} = true"
              else if value == false then "${name} = false"
              else if value == null then "${name} = nil"
              else if pkgs.lib.isDerivation value then "${name} = [[${value}]]"
              else if isList value then "${name} = ${luaListPrinter value}"
              else if isAttrs value then "${name} = ${luaTablePrinter value}"
              else "${name} = [[${toString value}]]"
            )
            attrSet;
          resultList = attrValues nameandstringmap;
          resultString = concatStringsSep ", " resultList;
        in
        resultString;
      catset = luatableformatter attrSet;
      LuaTable = "{ " + catset + " }";
    in
    LuaTable;

  # source: https://github.com/BirdeeHub/nixCats-nvim/blob/cd836e5/nix/utils/default.nix#L186-L203
  luaListPrinter = theList:
    let
      lualistformatter = theList:
        let
          stringlist = map
            (value:
              if value == true then "true"
              else if value == false then "false"
              else if value == null then "nil"
              else if pkgs.lib.isDerivation value then "[[${value}]]"
              else if isList value then "${luaListPrinter value}"
              else if isAttrs value then "${luaTablePrinter value}"
              else "[[${toString value}]]"
            )
            theList;
          resultString = concatStringsSep ", " stringlist;
        in
        resultString;
      catlist = lualistformatter theList;
      LuaList = "{ " + catlist + " }";
    in
    LuaList;

  # source: https://github.com/BirdeeHub/nixCats-nvim/blob/47a24db/nix/builder/vim-pack-dir.nix#L66-L93
  # (pretty heavily modified from source)
  allTreesitterGrammars = pkgs.stdenv.mkDerivation (
    let
      builderLines = map
        (grmr: ''cp --no-dereference ${grmr}/parser/*.so $out/parser'')
        (attrValues pkgs.vimPlugins.nvim-treesitter.grammarPlugins);

      builderText = ''
        #!/usr/bin/env bash
          source $stdenv/setup
          mkdir -p $out/parser
      '' + (concatStringsSep "\n" builderLines);
    in
    {
      name = "vimplugin-treesitter-grammar-ALL-INCLUDED";
      builder = pkgs.writeText "builder.sh" builderText;
    }
  );
}
