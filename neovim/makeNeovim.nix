{ pkgs, ... }:

{ extraPackages ? [ ]
, extraPython3Packages ? (p: [ ])
, startPlugins ? [ ]
, lazyPlugins ? [ ]
, withPython3 ? true
, withNodeJs ? true
, luaPath ? "${./.}"
, nvimAppName ? ""
}:
let
  inherit (import ./fromNixCats.nix { inherit pkgs; }) luaTablePrinter;

  #
  # user config as a plugin
  #
  userConfig = pkgs.stdenv.mkDerivation {
    name = "nln-user-config";
    builder = pkgs.writeText "builder.sh" /* bash */ ''
      source $stdenv/setup
      mkdir -p $out
      cp -r ${luaPath}/* $out/
    '';
  };

  #
  # convert a list of plugins into a dict we can modify, then pass to lazy.nvim
  #
  pluginsForConfig = builtins.foldl'
    (acc: elem: { "${elem.pname}" = { }; } // acc)
    { }
    lazyPlugins;
  pluginDirs = builtins.foldl'
    (acc: elem: { "${elem.pname}" = "${elem}"; } // acc)
    { }
    lazyPlugins;

  #
  # this file is how we pass build info (like paths) to lua config
  #
  generatedLuaFile = pkgs.writeText "generated.lua" /* lua */ ''
    -- DO NOT EDIT: this file was generated and will be overwritted
    local M = {}
    -- keep private so can't be modified, map pnames to store path
    pluginDirs = ${luaTablePrinter pluginDirs}
    -- mutable list of plugins to collect config
    M.plugins = ${luaTablePrinter pluginsForConfig}
    -- method to call after configuring to convert to list for lazy.nvim
    function M.plugins:for_lazy()
      local result = {}
      for p_name, p_cfg in pairs(self) do
        if type(p_cfg) ~= "function" then
          local lazy_spec = vim.tbl_extend("force", p_cfg, { dir = pluginDirs[p_name], name = p_name })
          table.insert(result, lazy_spec)
        end
      end
      return result
    end
    return M
  '';

  #
  # plugin containing paths etc generated at build time
  #
  nlnPlugin = pkgs.stdenv.mkDerivation {
    name = "nln-plugin";
    builder = pkgs.writeText "builder" /* bash */ ''
      source $stdenv/setup
      mkdir -p $out/lua/nln
      cat ${generatedLuaFile} > $out/lua/nln/init.lua
    '';
  };

  #
  # cfg for wrapNeovimUnstable
  #
  cfg = pkgs.neovimUtils.makeNeovimConfig {
    inherit extraPython3Packages withNodeJs withPython3;
    plugins = [ pkgs.vimPlugins.lazy-nvim ] ++ startPlugins;
    customRC = /* vim */ ''
      lua << EOF
        -- Ignore the user lua configuration
        vim.opt.runtimepath:remove(vim.fn.stdpath("config")) -- ~/.config/nvim
        vim.opt.runtimepath:remove(vim.fn.stdpath("config") .. "/after") -- ~/.config/nvim/after
        vim.opt.runtimepath:remove(vim.fn.stdpath("data") .. "/site") -- ~/.local/share/nvim/site

        vim.opt.rtp:prepend("${userConfig}")
        vim.opt.rtp:prepend("${nlnPlugin}")

        if vim.fn.filereadable("${userConfig}/init.lua") then
          vim.cmd("source ${userConfig}/init.lua")
        end
      EOF
    '';
  };

  #
  # wrapper args to pass to the final makeWrapper
  #
  extraWrapperArgs = cfg.wrapperArgs
    ++ [ "--suffix" "PATH" ":" (pkgs.lib.makeBinPath extraPackages) ]
    ++ (if nvimAppName == "" then [ ] else [ "--set" "NVIM_APPNAME" nvimAppName ]);
in
pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped (cfg // { wrapperArgs = extraWrapperArgs; })
