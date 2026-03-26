local M = {}

M.config = {
  ghostty_config_path = nil,
  watch = true,
  theme = nil,
  overrides = {},
  watch_interval = 1,
  theme_check_interval = 5,
}

local config_mod = require("ghostty-dynamic.config")
local theme_parser = require("ghostty-dynamic.theme_parser")
local highlighter = require("ghostty-dynamic.highlighter")

local timer = nil
local initialized = false

function M.get_system_appearance()
  return config_mod.get_system_appearance()
end

local function resolve_theme(theme_value, config_path)
  if not theme_value then
    return config_mod.get_current_theme_name(config_path)
  end

  if type(theme_value) == "table" then
    local appearance = config_mod.get_system_appearance()
    return theme_value[appearance]
  end

  if type(theme_value) == "string" then
    local light_theme, dark_theme = theme_value:match("^light:(.-)[,\n]%s*dark:(.-)$")
    if light_theme and dark_theme then
      local appearance = config_mod.get_system_appearance()
      if appearance == "dark" then
        return dark_theme
      else
        return light_theme
      end
    end
    return theme_value
  end

  return nil
end

function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})

  local config_path = M.config.ghostty_config_path
  if not config_path then
    config_path = config_mod.get_ghostty_config_path()
  end

  if not config_path then
    vim.notify("[ghostty-dynamic] Could not find Ghostty config", vim.log.levels.WARN)
    return
  end

  local theme_name = resolve_theme(M.config.theme, config_path)

  if not theme_name then
    vim.notify("[ghostty-dynamic] Could not determine theme from config", vim.log.levels.WARN)
    return
  end

  local theme_path = config_mod.find_theme_file(theme_name)
  if not theme_path then
    vim.notify("[ghostty-dynamic] Could not find theme file: " .. theme_name, vim.log.levels.WARN)
    return
  end

  local raw_theme = theme_parser.parse_theme_file(theme_path)
  if not raw_theme then
    vim.notify("[ghostty-dynamic] Failed to parse theme file: " .. theme_path, vim.log.levels.ERROR)
    return
  end

  local theme = theme_parser.expand_colors(raw_theme)
  highlighter.apply_theme(theme, M.config)

  local function refresh_lualine()
    if package.loaded["lualine"] then
      local lualine = require("lualine")
      local config = lualine.get_config()
      lualine.setup(config)
    else
      vim.defer_fn(refresh_lualine, 100)
    end
  end
  vim.defer_fn(refresh_lualine, 10)

  if M.config.watch and not initialized then
    initialized = true
    M._start_watcher()
  end
end

function M._start_watcher()
  local config_path = M.config.ghostty_config_path or config_mod.get_ghostty_config_path()
  if not config_path then
    return
  end

  if timer then
    timer:close()
  end

  local last_config_mtime = 0
  local last_theme_mtime = 0
  local watch_interval = M.config.watch_interval
  if watch_interval == nil then watch_interval = 1 end
  local theme_check_interval = M.config.theme_check_interval
  if theme_check_interval == nil then theme_check_interval = 5 end

  local function get_mtime(path)
    local stat = vim.loop.fs_stat(path)
    if stat then
      return stat.mtime.sec
    end
    return 0
  end

  local function check_config_changes()
    local new_config_mtime = get_mtime(config_path)
    if new_config_mtime > last_config_mtime and last_config_mtime > 0 then
      vim.schedule(function()
        M.setup(M.config)
      end)
      last_config_mtime = new_config_mtime
      return
    end
    last_config_mtime = new_config_mtime

    local theme_name = config_mod.get_current_theme_name(config_path)
    if theme_name then
      local theme_path = config_mod.find_theme_file(theme_name)
      if theme_path then
        local new_theme_mtime = get_mtime(theme_path)
        if new_theme_mtime > last_theme_mtime and last_theme_mtime > 0 then
          vim.schedule(function()
            M.setup(M.config)
          end)
        end
        last_theme_mtime = new_theme_mtime
      end
    end
  end

  local function check_system_theme()
    local current_appearance = config_mod.get_system_appearance()
    if M._last_system_appearance == nil then
      M._last_system_appearance = current_appearance
      vim.schedule(function()
        M.setup(M.config)
        if package.loaded["lualine"] then
          local lualine = require("lualine")
          local config = lualine.get_config()
          lualine.setup(config)
        end
      end)
    elseif current_appearance ~= M._last_system_appearance then
      M._last_system_appearance = current_appearance
      vim.schedule(function()
        M.setup(M.config)
        if package.loaded["lualine"] then
          local lualine = require("lualine")
          local config = lualine.get_config()
          lualine.setup(config)
        end
      end)
    end
  end

  last_config_mtime = get_mtime(config_path)
  local theme_name = config_mod.get_current_theme_name(config_path)
  if theme_name then
    local theme_path = config_mod.find_theme_file(theme_name)
    if theme_path then
      last_theme_mtime = get_mtime(theme_path)
    end
  end

  if watch_interval > 0 then
    timer = vim.loop.new_timer()
    if timer then
      timer:start(1000, watch_interval * 1000, vim.schedule_wrap(check_config_changes))
    end
  end

  local theme_timer = nil
  if theme_check_interval > 0 then
    theme_timer = vim.loop.new_timer()
    if theme_timer then
      theme_timer:start(theme_check_interval * 1000, theme_check_interval * 1000, vim.schedule_wrap(check_system_theme))
    end
  end

  vim.api.nvim_create_autocmd("VimLeave", {
    once = true,
    callback = function()
      if timer then
        timer:close()
      end
      if theme_timer then
        theme_timer:close()
      end
    end,
  })
end

return M
