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

- `init.lua` - Entry point that sets up lazy.nvim and loads all configs
- `lua/_cfg/` - Plugin configurations organized by category

## How It Works

1. **Nix provides**: neovim binary + lazy.nvim plugin + all treesitter grammars
2. **This directory provides**: All plugin specs and configuration via lazy.nvim
3. **Home-manager**: Automatically sources `init.lua` when nvim starts

This means:
- Treesitter grammars are pre-built via nix (fast, stable)
- All other plugins are managed by lazy.nvim (fast iteration)
- Edit any lua file, restart nvim, see changes instantly!
