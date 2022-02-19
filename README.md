# Luca's super simple neovim flake configuration

This configuration is heavily inspired by
[jordanisaacs/neovim-flake](https://github.com/jordanisaacs/neovim-flake)
and was forked, but heavily edited from [jordanisaacs/neovim-flake](https://github.com/jordanisaacs/neovim-flake).
The problem with their flakes (and pretty much all other (neovim-)flakes)
so far, is that the learning curve for flakes is so steep that only
experts know how to create them. This leads to eiter overly complex
examples or excessively trivial ones.

The above flakes are to complicated for most people, which is why
I simplified them into a small, single file. Now you can create your
own neovim flake in no time!

Just add your prefered plugins into the `inputs` section of `flake.nix`
and overwrite `init.vim`! Done!

## Installation

### Install system-wide

Open `/etc/nixos/flake.nix` and add the following:

```
inputs = {
    # ...blabla...
    neovim-flake.url = "github:Quoteme/neovim-flake";
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

Note that `...blabla...` is a placeholder for any other configuration
you might have set inside your `flake.nix`!

### Run from a folder (for hacking )

Clone the repo and run `nix run /some/file` inside the new folder.
