---@class snacks.picker.tea.Config: snacks.picker.Config
---@field state? "open" | "closed" | "all"
---@field limit? number number of items to fetch
---@field repo? string Forgejo repository (owner/repo). Defaults to current git repo
---@field remote? string git remote to use (default: "origin")
---@field login? string tea CLI login to use

local M = {}

---@class snacks.picker.tea.pr.Config: snacks.picker.tea.Config
M.tea_pr = function()
	local config = require("snacks.tea").config()
	local layout = config.layout and config.layout.pr_list or nil
	
	local base = {
		title = "  Forgejo Pull Requests",
		finder = "tea_pr",
		format = "tea_format",
		preview = "tea_preview",
		sort = { fields = { "score:desc", "idx" } },
		supports_live = true,
		live = true,
		confirm = "tea_actions",
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
	
	-- Merge layout config if provided
	if layout then
		base = vim.tbl_deep_extend("force", base, layout)
	end
	
	return base
end

---@class snacks.picker.tea.actions.Config: snacks.picker.Config
M.tea_actions = function()
	local config = require("snacks.tea").config()
	local layout = config.layout and config.layout.actions or nil
	
	local base = {
		title = "  Forgejo Actions",
		finder = require("snacks.picker.source.tea").actions,
		format = require("snacks.picker.source.tea").actions_format,
		sort = { fields = { "priority:desc", "idx" } },
	}
	
	-- Merge layout config if provided
	if layout then
		base = vim.tbl_deep_extend("force", base, layout)
	end
	
	return base
end

---@class snacks.picker.tea.diff.Config: snacks.picker.Config
---@field pr number PR number
---@field repo? string Forgejo repository (owner/repo). Defaults to current git repo
M.tea_diff = function()
	local config = require("snacks.tea").config()
	local layout = config.layout and config.layout.diff or nil
	
	local base = {
		title = "  Pull Request Diff",
		group = true,
		finder = "tea_diff",
		format = "git_status",
		preview = "tea_preview_diff",
		win = {
			preview = {
				keys = {
					["a"] = { "fg_comment", mode = { "n", "x" } },
					["<cr>"] = { "fg_actions", mode = { "n", "x" } },
				},
			},
		},
	}
	
	-- Merge layout config if provided
	if layout then
		base = vim.tbl_deep_extend("force", base, layout)
	end
	
	return base
end

return M
