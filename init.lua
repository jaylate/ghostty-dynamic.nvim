local M = {}

M.config = {
  ghostty_config_path = nil,
  watch = true,
  theme = nil,
  overrides = {},
}

local config_mod = require("ghostty-dynamic.config")
local theme_parser = require("ghostty-dynamic.theme_parser")
local highlighter = require("ghostty-dynamic.highlighter")

local timer = nil
local initialized = false

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

  local theme_name = M.config.theme
  if not theme_name then
    theme_name = config_mod.get_current_theme_name(config_path)
  end

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

  local function get_mtime(path)
    local stat = vim.loop.fs_stat(path)
    if stat then
      return stat.mtime.sec
    end
    return 0
  end

  local function check_changes()
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

  last_config_mtime = get_mtime(config_path)
  local theme_name = config_mod.get_current_theme_name(config_path)
  if theme_name then
    local theme_path = config_mod.find_theme_file(theme_name)
    if theme_path then
      last_theme_mtime = get_mtime(theme_path)
    end
  end

  timer = vim.loop.new_timer()
  if not timer then
    return
  end

  timer:start(1000, 1000, vim.schedule_wrap(check_changes))

  vim.api.nvim_create_autocmd("VimLeave", {
    once = true,
    callback = function()
      if timer then
        timer:close()
      end
    end,
  })
end

return M
