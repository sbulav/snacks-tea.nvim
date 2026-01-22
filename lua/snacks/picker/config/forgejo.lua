---@class snacks.picker.forgejo.Config: snacks.picker.Config
---@field state? "open" | "closed" | "all"
---@field limit? number number of items to fetch
---@field repo? string Forgejo repository (owner/repo). Defaults to current git repo
---@field remote? string git remote to use (default: "origin")
---@field login? string tea CLI login to use

local M = {}

---@class snacks.picker.forgejo.pr.Config: snacks.picker.forgejo.Config
M.forgejo_pr = {
  title = "  Forgejo Pull Requests",
  finder = "forgejo_pr",
  format = "forgejo_format",
  preview = "forgejo_preview",
  sort = { fields = { "score:desc", "idx" } },
  supports_live = true,
  live = true,
  confirm = "forgejo_actions",
  win = {
    input = {
      keys = {
        ["<a-b>"] = { "fg_browse", mode = { "n", "i" } },
        ["<c-y>"] = { "fg_yank", mode = { "n", "i" } },
      },
    },
    list = {
      keys = {
        ["y"] = { "fg_yank", mode = { "n", "x" } },
      },
    },
  },
}

---@class snacks.picker.forgejo.actions.Config: snacks.picker.Config
M.forgejo_actions = {
  title = "  Forgejo Actions",
  finder = require("snacks.picker.source.forgejo").actions,
  format = require("snacks.picker.source.forgejo").actions_format,
  sort = { fields = { "priority:desc", "idx" } },
}

return M
