# Agent Guidelines for nixfiles

This repository contains NixOS and Home Manager configurations using Nix flakes. It manages system and user-level configurations (including a large nvim config) for multiple hosts.

## Project Structure

```
nixfiles/
├── flake.nix              # Main flake configuration
├── modules/               # Reusable NixOS and home-manager modules
│   ├── nixos/            # NixOS system modules
│   └── home-manager/     # Home Manager user modules
├── hosts/                 # Host-specific configurations (tui, kakapo, etc.)
├── users/                 # User-specific home configurations
├── dots/                  # Dotfiles (deployed via GNU stow)
├── scripts/              # Utility shell scripts
├── justfile              # Command runner tasks
└── statix.toml           # Nix linter configuration
```

## Build, Lint, and Test Commands

### Primary Commands (via just)

```bash
just                      # List all available commands
just build                # Build configuration without applying to check for nix issues
just stow                 # Deploy dotfiles using stow
```

## Code Style Guidelines

### Nix Files

#### Module Structure

Standard module pattern (use consistently):

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.modules.<module-name>;
in
{
  options.modules.<module-name> = {
    enable = lib.mkEnableOption "description";
    # other options...
  };

  config = lib.mkIf cfg.enable {
    # configuration here
  };
}
```

#### Comments
- Use `#` for single-line comments
- Place above code, not inline
- Explain "why" not "what"
- Include external references: `# @see: https://...`

#### Platform Conditionals

```nix
if pkgs.stdenv.isLinux then linuxPackages else darwinPackages
```

### Shell Scripts

- Use `#!/bin/sh` shebang (POSIX shell)
- Add `set -e` for error handling
- Quote variables: `"$VARIABLE"`
- Prefer long flags for clarity: `--verbose` over `-v`

## Common Patterns

### Adding a New Module

1. Create module file: `modules/nixos/my-feature.nix` or `modules/home-manager/my-feature.nix`
2. Use standard module structure (see above)
3. Import in `flake.nix` modules list
4. Enable with `modules.my-feature.enable = true;`

### Accessing Unstable Packages

```nix
# Available as extraSpecialArgs in flake.nix
{ pkgs, pkgs-unstable, ... }:
{
  home.packages = [
    pkgs-unstable.some-newer-package
  ];
}
```

## Neovim Config

Located in `dots/.config/nvim/`

### Plugin Management

**Hybrid System: Nix + lazy.nvim**. Installing lazy via nix saves bootstrapping it. And some plugins have compiled dependencies, which nix deals with better.

- Nix-managed plugins:
  - Installed via `modules/home-manager/devtools.nix`
  - Configured in `lua/config/` (NOT `lua/plugins/`)
  - Loaded in `init.lua` BEFORE lazy.nvim setup
- lazy.nvim-managed: Everything else
  - Automatically discovered from `lua/plugins/*.lua`
  - Versions locked in `lazy-lock.json`

### Directory Structure

```
dots/.config/nvim/
├── init.lua                # Entry point
├── lazy-lock.json          # Plugin versions
├── lua/
│   ├── config/             # Core vim settings (no plugins)
│   └── plugins/            # Plugin specs by category
└── snippets/               # VSCode-format snippets
```

### Keybinding Conventions

**Leader key:** `<Space>` (both leader and localleader)

**Prefix Organization:**
- `<leader>f` - Find/search (telescope)
- `<leader>l` - LSP operations
- `<leader>g` - Git operations
- `<leader>e` - File explorer
- `<leader>d` - Debugging (DAP)
- `<leader>h` - Git hunks
- `,<key>` - Quick actions (`,f` find files, `,a` live grep)
- `\<key>` - Toggles (`\d` diagnostics, `\f` format-on-save)
- `gd`/`gh`/`gI` - LSP go-to operations

**Always include** `desc` parameter for discoverability.

### File Organization Philosophy

- related plugins in same file
- `config/` for vim settings, `plugins/` for plugin specs
- Follow vanilla vim/neovim patterns where practical

### Getting Docs and Debugging

**Test changes headlessly:**
```bash
# Check if config loads without errors
nvim --headless -c 'quit' && echo "OK" || echo "Failed"

# Test specific lua file
nvim --headless -c 'luafile lua/plugins/lsp.lua' -c 'quit'
```

**Find doc files for grepping:**
- `:help` is interactive and will hang if called headlessly, you must search plugin source code for docs
- sometime help docs are not complete, and searching plugin source code is required too
```bash
# Print all runtime paths (includes plugin doc dirs)
nvim --headless -c 'lua print(vim.inspect(vim.api.nvim_list_runtime_paths()))' -c 'quit'

# Print lazy plugin root
nvim --headless -c 'lua print(require("lazy.core.config").options.root)' -c 'quit'

# Then grep doc files
rg "pattern" ~/.local/share/nvim/lazy/*/doc/*.txt
```

**Debug print values:**
```bash
nvim --headless -c 'lua vim.print(vim.fn.stdpath("config"))' -c 'quit'
nvim --headless -c 'lua vim.print(require("lazy.core.config").plugins["telescope.nvim"])' -c 'quit'
```
