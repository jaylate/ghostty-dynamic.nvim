-- ghostty-dynamic.nvim
-- Automatically apply Ghostty theme colors to Neovim

-- Add plugin's lua directory to runtime path
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/lazy/ghostty-dynamic.nvim/lua")

-- Pre-load background to prevent flash of default theme
local ok, bg = pcall(require("ghostty-dynamic.config").get_background_color)
if ok and bg then
  vim.cmd("hi Normal guibg=" .. bg)
end

-- Load full theme at VimEnter
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    pcall(require("ghostty-dynamic").setup, {
      watch = true,
    })
  end,
})
