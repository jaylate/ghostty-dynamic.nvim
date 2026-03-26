local M = {}

M._last_theme = nil
M._last_opts = nil
M._expected_bg = nil

local applying = false

local function set_hl(group, opts)
  if not opts then
    return
  end
  vim.api.nvim_set_hl(0, group, opts)
end

local function is_light_bg(hex)
  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)
  return (0.299 * r + 0.587 * g + 0.114 * b) / 255 > 0.5
end

function M.apply_theme(theme, opts)
  if applying then return end
  applying = true

  M._last_theme = theme
  M._last_opts = opts

  local ok, err = pcall(function()
    opts = opts or {}
    local overrides = opts.overrides or {}

    local bg = theme.background or "#000000"
    local fg = theme.foreground or "#ffffff"

    local palette = {}
    for i = 0, 15 do
      palette[i] = theme.palette[i] or (i < 8 and "#000000" or "#ffffff")
    end

    vim.cmd("noautocmd set background=" .. (is_light_bg(bg) and "light" or "dark"))

    set_hl("Normal", { fg = fg, bg = bg })
    set_hl("NormalNC", { fg = fg, bg = bg })
    set_hl("NormalFloat", { fg = fg, bg = bg })
    set_hl("Cursor", { fg = theme.cursor_color or bg, bg = fg })
    set_hl("CursorIM", { fg = theme.cursor_color or bg, bg = fg })
    set_hl("CursorLine", { bg = overrides.cursor_line or palette[7] })
    set_hl("LineNr", { fg = palette[8] })
    set_hl("CursorLineNr", { fg = fg, bold = true })
    set_hl("Visual", { bg = theme.selection_background or palette[8], fg = theme.selection_foreground or fg })
    set_hl("VisualNOS", { bg = theme.selection_background or palette[8], fg = theme.selection_foreground or fg })
    set_hl("Search", { fg = bg, bg = palette[3] })
    set_hl("IncSearch", { fg = bg, bg = palette[3] })
    set_hl("Pmenu", { fg = fg, bg = palette[7] })
    set_hl("PmenuSel", { fg = bg, bg = fg })
    set_hl("PmenuSbar", { bg = palette[7] })
    set_hl("PmenuThumb", { bg = palette[8] })
    set_hl("SpellBad", { fg = palette[1], undercurl = true })
    set_hl("SpellCap", { fg = palette[4], undercurl = true })
    set_hl("SpellRare", { fg = palette[5], undercurl = true })
    set_hl("SpellLocal", { fg = palette[6], undercurl = true })
    set_hl("MatchParen", { fg = palette[3], bold = true })
    set_hl("TabLineFill", { fg = fg, bg = bg })
    set_hl("TabLineSel", { fg = bg, bg = fg })
    set_hl("TabLine", { fg = fg, bg = bg })
    set_hl("StatusLine", { fg = fg, bg = bg })
    set_hl("StatusLineNC", { fg = palette[8], bg = bg })
    set_hl("VertSplit", { fg = palette[8], bg = bg })
    set_hl("Title", { fg = fg, bold = true })
    set_hl("Bold", { bold = true })
    set_hl("Italic", { italic = true })
    set_hl("Underlined", { underline = true })
    set_hl("Directory", { fg = palette[4] })
    set_hl("DiffAdd", { fg = palette[2] })
    set_hl("DiffChange", { fg = palette[3] })
    set_hl("DiffDelete", { fg = palette[1] })
    set_hl("DiffText", { fg = fg })
    set_hl("Error", { fg = palette[1] })
    set_hl("ErrorMsg", { fg = palette[1], bg = bg })
    set_hl("WarningMsg", { fg = palette[3] })
    set_hl("MoreMsg", { fg = palette[4] })
    set_hl("Question", { fg = palette[5] })
    set_hl("ModeMsg", { fg = fg })
    set_hl("MsgSeparator", { fg = palette[8] })
    set_hl("MsgArea", { fg = fg })
    set_hl("Folded", { fg = palette[8], bg = palette[7] })
    set_hl("FoldColumn", { fg = palette[8] })
    set_hl("SignColumn", { fg = fg })
    set_hl("Conceal", { fg = palette[8] })
    set_hl("WinSeparator", { fg = palette[8] })
    set_hl("NonText", { fg = palette[8] })
    set_hl("SpecialKey", { fg = palette[8] })
    set_hl("Comment", { fg = palette[8], italic = true })
    set_hl("Constant", { fg = palette[5] })
    set_hl("String", { fg = palette[2] })
    set_hl("Number", { fg = palette[5] })
    set_hl("Boolean", { fg = palette[5] })
    set_hl("Float", { fg = palette[5] })
    set_hl("Identifier", { fg = palette[6] })
    set_hl("Function", { fg = palette[4] })
    set_hl("Statement", { fg = palette[1] })
    set_hl("Conditional", { fg = palette[1] })
    set_hl("Repeat", { fg = palette[1] })
    set_hl("Label", { fg = palette[1] })
    set_hl("Operator", { fg = fg })
    set_hl("Keyword", { fg = palette[1] })
    set_hl("PreProc", { fg = palette[3] })
    set_hl("Include", { fg = palette[4] })
    set_hl("Define", { fg = palette[3] })
    set_hl("Macro", { fg = palette[3] })
    set_hl("Type", { fg = palette[3] })
    set_hl("StorageClass", { fg = palette[3] })
    set_hl("Structure", { fg = palette[3] })
    set_hl("Typedef", { fg = palette[3] })
    set_hl("Special", { fg = palette[4] })
    set_hl("SpecialChar", { fg = palette[5] })
    set_hl("Tag", { fg = palette[2] })
    set_hl("Delimiter", { fg = fg })
    set_hl("SpecialComment", { fg = palette[8] })
    set_hl("Debug", { fg = palette[1] })
    set_hl("Whitespace", { fg = palette[8] })
    set_hl("DiagnosticError", { fg = palette[1] })
    set_hl("DiagnosticWarn", { fg = palette[3] })
    set_hl("DiagnosticHint", { fg = palette[6] })
    set_hl("DiagnosticInfo", { fg = palette[4] })
    set_hl("DiagnosticUnderlineError", { undercurl = true, sp = palette[1] })
    set_hl("DiagnosticUnderlineWarn", { undercurl = true, sp = palette[3] })
    set_hl("DiagnosticUnderlineHint", { undercurl = true, sp = palette[6] })
    set_hl("DiagnosticUnderlineInfo", { undercurl = true, sp = palette[4] })

    set_hl("@string", { fg = palette[2] })
    set_hl("@number", { fg = palette[5] })
    set_hl("@boolean", { fg = palette[5] })
    set_hl("@float", { fg = palette[5] })
    set_hl("@keyword", { fg = palette[1] })
    set_hl("@keyword.function", { fg = palette[1] })
    set_hl("@keyword.operator", { fg = palette[1] })
    set_hl("@operator", { fg = fg })
    set_hl("@punctuation", { fg = fg })
    set_hl("@punctuation.delimiter", { fg = fg })
    set_hl("@constant", { fg = palette[5] })
    set_hl("@constant.builtin", { fg = palette[5] })
    set_hl("@variable", { fg = fg })
    set_hl("@variable.builtin", { fg = palette[5] })
    set_hl("@type", { fg = palette[3] })
    set_hl("@type.builtin", { fg = palette[3] })
    set_hl("@function", { fg = palette[4] })
    set_hl("@function.builtin", { fg = palette[4] })
    set_hl("@function.call", { fg = palette[4] })
    set_hl("@method", { fg = palette[4] })
    set_hl("@method.call", { fg = palette[4] })
    set_hl("@namespace", { fg = palette[3] })
    set_hl("@tag", { fg = palette[2] })
    set_hl("@tag.attribute", { fg = palette[3] })
    set_hl("@tag.delimiter", { fg = fg })
    set_hl("@comment", { fg = palette[8], italic = true })
    set_hl("@comment.documentation", { fg = palette[8], italic = true })
    set_hl("@property", { fg = palette[6] })
    set_hl("@field", { fg = palette[6] })
    set_hl("@attribute", { fg = palette[3] })
    set_hl("@module", { fg = palette[4] })

    M._expected_bg = bg

    vim.g.colors_name = "ghostty-dynamic"
    vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "ghostty-dynamic" })
  end)

  applying = false

  if not ok then
    vim.notify("[ghostty-dynamic] Error applying theme: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  vim.g._ghostty_apply_gen = (vim.g._ghostty_apply_gen or 0) + 1
  local gen = vim.g._ghostty_apply_gen
  for i = 1, 5 do
    vim.defer_fn(function()
      if gen == vim.g._ghostty_apply_gen and M._last_theme and not M.is_theme_intact() then
        M.apply_theme(M._last_theme, M._last_opts)
      end
    end, i * 200)
  end
end

function M.is_theme_intact()
  if not M._expected_bg then return true end
  local actual = vim.api.nvim_get_hl(0, { name = "Normal" })
  if not actual.bg then return false end
  return string.format("#%06x", actual.bg) == M._expected_bg
end

return M
