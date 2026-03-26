# ghostty-dynamic.nvim

**WARNING:** This plugin is fully vibe coded. Not affiliated with Ghostty. Inspired by [ghostty-theme-sync.nvim](https://github.com/landerson02/ghostty-theme-sync.nvim) but it didn't work for me since themes need to exist in both Ghostty and Neovim.

A Neovim plugin that automatically applies your Ghostty terminal theme colors to Neovim, supporting ALL Ghostty themes without manual configuration.

## Features

- **Automatic Theme Sync**: Reads your Ghostty config and applies the current theme colors to Neovim on startup
- **Works with ALL Ghostty Themes**: No need for matching nvim colorschemes - any of the 430+ Ghostty themes work out of the box
- **Auto-reload**: Watches for Ghostty config/theme changes and updates nvim automatically
- **Full Syntax Highlighting**: Applies theme colors to syntax highlighting, lualine, and all nvim highlight groups

## Installation

### Using Lazy.nvim

```lua
{
  "jaylate/ghostty-dynamic.nvim",
  lazy = false,
  priority = 1000,
}
```

## Configuration

The plugin works out of the box, but you can customize:

```lua
-- Default options (can be overridden in setup)
require("ghostty-dynamic").setup({
  -- Path to Ghostty config file (auto-detected if nil)
  ghostty_config_path = nil,
  
  -- Watch for config changes and auto-reload
  watch = true,
  
  -- Override theme name (skip reading Ghostty config)
  -- Can be a string, table, or nil
  theme = nil,
  
  -- Custom highlight overrides
  overrides = {},

  -- Interval in seconds to check for Ghostty config file changes (default: 1)
  -- Set to 0 to disable automatic reload on config changes
  watch_interval = 1,

  -- Interval in seconds to check for system theme changes (default: 5)
  -- Set to 0 to disable automatic theme switching on system theme change
  theme_check_interval = 5,
})
```

### Light/Dark Mode Support

The plugin supports automatic theme switching based on system appearance:

**Supported system theme detection:**
- GNOME Linux: `gsettings get org.gnome.desktop.interface color-scheme`
- macOS: `dark-mode` command

**Usage options:**

1. **String syntax** (same as Ghostty config):
```lua
require("ghostty-dynamic").setup({
  theme = "light:Catppuccin Latte,dark:Catppuccin Frappe",
})
```

2. **Table syntax**:
```lua
require("ghostty-dynamic").setup({
  theme = {
    light = "Catppuccin Latte",
    dark = "Catppuccin Frappe",
  },
})
```

3. **From Ghostty config**: The plugin automatically reads `theme = light:X,dark:Y` from your Ghostty config file.

### Helper Functions

- `require("ghostty-dynamic").get_system_appearance()` - Returns `"light"` or `"dark"` based on system theme

## Usage

The plugin loads automatically on nvim startup. When you change your Ghostty theme:

1. Change theme in `~/.config/ghostty/config`:
   ```ini
   theme = Nord
   ```

2. Reload Ghostty config (default: `ctrl+shift+,` on Linux)

3. Neovim will automatically pick up the new theme within 1 second

### Commands

- `:GhosttyThemeReload` - Manually reload the theme

## How It Works

1. Pre-loads background color before UI renders (prevents flash)
2. Reads the `theme` setting from your Ghostty config on UIEnter
3. Finds the corresponding theme file in Ghostty's theme directory
4. Parses the theme file (background, foreground, palette colors)
5. Maps Ghostty colors to nvim highlight groups
6. Applies highlights to Neovim
7. Watches for config/theme file changes and auto-reloads

## Requirements

- Neovim 0.9+
- Ghostty terminal

## Theme File Locations

Ghostty themes are searched in:
- `~/.config/ghostty/themes/`
- `/usr/share/ghostty/themes/` (Linux)
- Built-in Ghostty themes

## License

MIT
