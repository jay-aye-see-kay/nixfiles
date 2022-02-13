# Neovim config using Nix flakes

This configuration is heavily inspired by [jordanisaacs/neovim-flake](https://github.com/jordanisaacs/neovim-flake)

## Installation

In order to test the configuration, you can clone this repository and execute the follwing command:
```
nix run .# -- /some/file
```

### Home Manager

This flake can easily be installed in home-manager using the `home-managerModule` output.

If you are using non-NixOS home-manager it will look something like:

```nix
homeManager.lib.homeManagerConfiguration {
    configuration = { config, lib, pkgs, ...}: {
        imports = [ inputs.nvim-flake.home-managerModule."${system}" ];
    };

    pkgs = import nixpkgs {
        overlays = [ inputs.nvim-flake.overlay."${system}" ];
    };
}
```

In case of a NixOS system it will look like:

```nix
{
    modules = [
        ({ pkgs, ... }: {
            nixpkgs.overlays = [
              inputs.nvim-flake.overlay."${system}"
            ];
        })
        home-manager.nixosModules.home-manager
        {
            home-manager.users.foo = {config, lib, pkgs, ...}: {
                imports = [ inputs.nvim-flake.home-managerModule."${system}" ];
            };
        }
    ];
}
```

## Adding plugins

If you want to add a plugin you can just add an input in the inputs with the name `plugin:<some name>`. You can then add `pkgs.neovimPlugins.<some name>` to `vim.startPlugins = [ ... ]`.

If you want to add an nvim-cmp-source you will need to add a plugin of the form `plugin:cmp-source-<cmp source name>`. The plugin can be added in the same way, and you can enable the `<cmp source name>` in the `vim.completion.sources` option.

## Configuration

Everything that can be configured is in the `./config.nix` and it's imports
