local M = {}

local function file_exists(path)
  return vim.loop.fs_stat(path) ~= nil
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

function M.get_current_theme_name(config_path)
  if not config_path or not file_exists(config_path) then
    return nil
  end

  for line in io.lines(config_path) do
    local theme = line:match("^theme%s*=%s*(.+)")
    if theme then
      theme = theme:gsub("%s+", "")

      local light, dark = theme:match("light:(%w+)%,?dark:(%w+)")
      if light and dark then
        local appearance = vim.loop.os_uname().sysname
        if appearance == "Darwin" or appearance == "Linux" then
          local handle = io.popen("dark-mode 2>/dev/null || cat /sys/class/dmi/id/product_version 2>/dev/null || echo 'unknown'")
          if handle then
            local result = handle:read("*a"):match("%S+")
            handle:close()
            if result and result:find("[Aa]pple") or result:find("mac") then
              return dark
            end
          end
          return dark
        end
        return dark
      end

      return theme:gsub('"', ""):gsub("'", "")
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
