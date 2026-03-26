local M = {}

local function file_exists(path)
  return vim.loop.fs_stat(path) ~= nil
end

function M.get_system_appearance()
  local uname = vim.loop.os_uname().sysname
  if uname == "Linux" then
    local handle = io.popen("gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null")
    if handle then
      local result = handle:read("*a")
      handle:close()
      if result and result:match("prefer%-dark") then
        return "dark"
      end
    end
  elseif uname == "Darwin" then
    local handle = io.popen("dark-mode 2>/dev/null")
    if handle then
      local result = handle:read("*a")
      handle:close()
      if result and result:match("on") then
        return "dark"
      end
    end
  end

  return "light"
end

function M.get_ghostty_config_path()
  local xdg = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
  local paths = {
    xdg .. "/ghostty/config.ghostty",
    xdg .. "/ghostty/config",
    os.getenv("HOME") .. "/.config/ghostty/config.ghostty",
    os.getenv("HOME") .. "/.config/ghostty/config",
  }

  for _, path in ipairs(paths) do
    if file_exists(path) then
      return path
    end
  end

  return nil
end

function M.resolve_appearance_theme(theme_str)
  local light_theme, dark_theme = theme_str:match("^light:(.-)[,\n]%s*dark:(.-)$")
  if not light_theme or not dark_theme then
    return nil
  end
  local appearance = M.get_system_appearance()
  if appearance == "dark" then
    return dark_theme:gsub('"', ""):gsub("'", "")
  end
  return light_theme:gsub('"', ""):gsub("'", "")
end

function M.get_current_theme_name(config_path)
  if not config_path or not file_exists(config_path) then
    return nil
  end

  for line in io.lines(config_path) do
    local theme = line:match("^theme%s*=%s*(.+)")
    if theme then
      theme = theme:gsub("%s+", "")
      return M.resolve_appearance_theme(theme) or theme:gsub('"', ""):gsub("'", "")
    end
  end

  return nil
end

function M.get_theme_locations()
  local xdg = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
  local locations = {}

  table.insert(locations, xdg .. "/ghostty/themes")

  local system_paths = {
    "/usr/share/ghostty/themes",
    "/usr/local/share/ghostty/themes",
  }

  for _, path in ipairs(system_paths) do
    if file_exists(path) then
      table.insert(locations, path)
    end
  end

  return locations
end

function M.find_theme_file(theme_name)
  if not theme_name then
    return nil
  end

  local locations = M.get_theme_locations()

  local function try_paths(base_name)
    for _, dir in ipairs(locations) do
      local test_paths = {
        dir .. "/" .. base_name,
        dir .. "/" .. base_name .. ".theme",
      }
      for _, path in ipairs(test_paths) do
        if file_exists(path) then
          return path
        end
      end
    end
    return nil
  end

  local path = try_paths(theme_name)
  if path then
    return path
  end

  local function insert_spaces(s)
    return (s:gsub("(%d)(%u)", "%1 %2"):gsub("(%u)(%u%l)", "%1 %2"):gsub("(%l)(%u)", "%1 %2"))
  end

  local variations = {
    theme_name:gsub("%-", " "),
    theme_name:gsub(" ", "-"),
    theme_name:gsub("_", " "),
    insert_spaces(theme_name),
    insert_spaces(theme_name:gsub("%-", " ")),
  }

  for _, v in ipairs(variations) do
    if v ~= theme_name then
      path = try_paths(v)
      if path then
        return path
      end
    end
  end

  return nil
end

function M.get_background_color()
  local config_path = M.get_ghostty_config_path()
  if not config_path then
    return nil
  end

  local theme_name = M.get_current_theme_name(config_path)
  if not theme_name then
    return nil
  end

  local theme_path = M.find_theme_file(theme_name)
  if not theme_path then
    return nil
  end

  local theme_parser = require("ghostty-dynamic.theme_parser")
  local theme = theme_parser.parse_theme_file(theme_path)
  if not theme or not theme.background then
    return nil
  end

  return "#" .. theme.background
end

return M
