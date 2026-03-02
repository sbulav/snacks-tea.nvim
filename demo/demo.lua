-- Demo config for snacks-tea.nvim recordings
-- Usage: nvim -u demo/demo.lua

local root = vim.fn.getcwd()

vim.opt.runtimepath:prepend(root)
vim.g.mapleader = " "

vim.opt.termguicolors = true
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.signcolumn = "no"
vim.opt.foldcolumn = "0"
vim.opt.laststatus = 2
vim.opt.cmdheight = 1
vim.opt.showmode = false
vim.opt.mouse = ""
vim.opt.wrap = false

local function bootstrap_lazy()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.uv.fs_stat(lazypath) then
    local clone = vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      lazypath,
    })
    if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({ { "Failed to install lazy.nvim: " .. clone, "ErrorMsg" } }, true, {})
      return false
    end
  end
  vim.opt.runtimepath:prepend(lazypath)
  return true
end

if not bootstrap_lazy() then
  return
end

require("lazy").setup({
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    dependencies = {
      {
        dir = root,
        name = "snacks-tea.nvim",
        dev = true,
      },
    },
    opts = {
      picker = { enabled = true },
      tea = {
        enabled = true,
        tea = {
          cmd = root .. "/demo/tea-demo",
          remote = "origin",
          login = "demo",
        },
        ui = {
          scratch = {
            width = 100,
            height = 18,
          },
        },
        layout = {
          pr_list = {
            preset = "ivy",
            layout = {
              width = 0.96,
              height = 0.84,
            },
          },
          actions = {
            preset = "select",
            layout = {
              max_width = 64,
              max_height = 12,
            },
          },
          create = {
            scratch = {
              width = 100,
              height = 18,
            },
          },
        },
      },
    },
  },
}, {
  change_detection = { notify = false },
  checker = { enabled = false },
})

for _, cs in ipairs({ "tokyonight", "catppuccin", "gruvbox" }) do
  if pcall(vim.cmd.colorscheme, cs) then
    break
  end
end

local function open_demo_picker()
  local tea = require("snacks.tea")
  tea.setup()

  if Snacks.picker and Snacks.picker.tea_pr then
    return Snacks.picker.tea_pr({})
  end

  local source = require("snacks.picker.source.tea")
  return Snacks.picker({
    title = "  Forgejo Pull Requests",
    finder = source.pr,
    format = source.format,
    preview = source.preview,
    sort = { fields = { "score:desc", "idx" } },
    supports_live = true,
    live = true,
    confirm = "tea_actions",
    layout = {
      preset = "ivy",
      layout = {
        width = 0.96,
        height = 0.84,
      },
    },
  })
end

vim.api.nvim_create_user_command("TeaDemo", open_demo_picker, {
  desc = "Open snacks-tea demo picker",
})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.defer_fn(open_demo_picker, 500)
  end,
})
