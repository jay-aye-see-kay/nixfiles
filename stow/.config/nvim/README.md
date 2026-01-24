# Neovim Configuration

This is the new lazy.nvim-based neovim configuration.

## Setup

From the nixfiles root directory, run:

```bash
just stow-nvim
```

This will symlink this directory to `~/.config/nvim/`.

## Usage

- Run `nvim` to use this configuration
- Run `nnvim` to use the old nix-managed configuration (during transition)

## Plugin Management

All plugins are managed by lazy.nvim and will be downloaded on first run.
LSPs, formatters, and debuggers are provided by the nix devtools module.

## Directory Structure

- `init.lua` - Entry point, bootstraps lazy.nvim
- `lua/_cfg/` - Plugin configurations organized by category
