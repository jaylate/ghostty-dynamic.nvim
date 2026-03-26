local M = {}

local function file_exists(path)
  return vim.loop.fs_stat(path) ~= nil
end

local function trim(s)
  return s:match("^%s*(.-)%s*$")
end

function M.parse_theme_file(file_path)
  if not file_path or not file_exists(file_path) then
    return nil
  end

  local theme = {
    background = nil,
    foreground = nil,
    cursor_color = nil,
    cursor_text = nil,
    selection_background = nil,
    selection_foreground = nil,
    palette = {},
  }

  for line in io.lines(file_path) do
    line = trim(line)

    if line == "" or line:match("^#") then
      goto continue
    end

    local key, value = line:match("^([^=]+)=(.+)")
    if key and value then
      key = trim(key)
      value = trim(value)

      if key == "background" then
        theme.background = value:gsub("#", "")
      elseif key == "foreground" then
        theme.foreground = value:gsub("#", "")
      elseif key == "cursor-color" then
        theme.cursor_color = value:gsub("#", "")
      elseif key == "cursor-text" then
        theme.cursor_text = value:gsub("#", "")
      elseif key == "selection-background" then
        theme.selection_background = value:gsub("#", "")
      elseif key == "selection-foreground" then
        theme.selection_foreground = value:gsub("#", "")
      elseif key == "palette" then
        local index_str, color = value:match("^(%d+)=(.+)$")
        local index = tonumber(index_str)
        if index and color then
          theme.palette[index] = color:gsub("#", "")
        end
      end
    end

    ::continue::
  end

  if not theme.background then
    return nil
  end

  return theme
end

function M.expand_colors(theme)
  local expanded = vim.deepcopy(theme)

  local function fix_color(c)
    if not c then
      return nil
    end
    if #c == 6 then
      return "#" .. c
    end
    return c
  end

  expanded.background = fix_color(expanded.background)
  expanded.foreground = fix_color(expanded.foreground)
  expanded.cursor_color = fix_color(expanded.cursor_color)
  expanded.cursor_text = fix_color(expanded.cursor_text)
  expanded.selection_background = fix_color(expanded.selection_background)
  expanded.selection_foreground = fix_color(expanded.selection_foreground)

  for i, color in pairs(expanded.palette) do
    expanded.palette[i] = fix_color(color)
  end

  return expanded
end

return M
