# Neovim flake configuration

Kept separate so I can update it when I feel like, independent from the rest of my Nix system.

## Installation

### Run over the internet

`nix run github:jay-aye-see-kay/neovim-flake /some/file`

### Install with an overlay

TODO

### Install system-wide

Open `/etc/nixos/flake.nix` and add the following:

```nix
inputs = {
    neovim-flake.url = "github:jay-aye-see-kay/neovim-flake";
}

outputs = {self, nixpkgs, ...}@attr: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
            ({ config, nixpkgs, ...}@inputs:
                # ...blabla...
                environment.systemPackages = with pkgs; [
                    # ...blabla...
                    inputs.neovim-flake.defaultPackage.x86_64-linux
                ];
            )
        ];
    }
}
```
