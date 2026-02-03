local Actions = require("snacks.tea.actions")
local Api = require("snacks.tea.api")

local M = {}

M.actions = setmetatable({}, {
	__index = function(t, k)
		if type(k) ~= "string" then
			return
		end
		if not Actions.actions[k] then
			return nil
		end
		---@type snacks.picker.Action
		local action = {
			desc = Actions.actions[k].desc,
			action = function(picker, item, action)
				local items = picker:selected({ fallback = true })
				if item.tea_item then
					item = item.tea_item
					items = { item }
				end
				---@diagnostic disable-next-line: param-type-mismatch
				return Actions.actions[k].action(item, {
					picker = picker,
					items = items,
					action = action,
				})
			end,
		}
		rawset(t, k, action)
		return action
	end,
})

---@param opts snacks.picker.tea.Config
---@type snacks.picker.finder
function M.pr(opts, ctx)
	if ctx.filter.search ~= "" then
		opts.search = ctx.filter.search
	end
	---@async
	return function(cb)
		Api.list("pr", function(items)
			if items then
				for _, item in ipairs(items) do
					cb(item)
				end
			end
		end, opts):wait()
	end
end

---@type snacks.picker.format
function M.format(item)
	local config = require("snacks.tea").config()
	local ret = {} ---@type snacks.picker.Highlight[]
	local icons = config.icons
	local ui_hl = config.ui and config.ui.highlights or {}

	-- State icon with dynamic highlight
	local state_icon = icons.pr[item.state] or icons.pr.other
	local state_hl_name = (ui_hl.pr_state and ui_hl.pr_state[item.state]) 
		or "SnacksTeaPr" .. item.state:sub(1, 1):upper() .. item.state:sub(2)
	ret[#ret + 1] = { state_icon .. " ", state_hl_name }

	-- PR number with dynamic highlight
	local number_hl = ui_hl.number or "Number"
	ret[#ret + 1] = { "#" .. item.number .. " ", number_hl }

	-- Title with dynamic highlight
	local title_hl = ui_hl.title or "Normal"
	ret[#ret + 1] = { item.title or "", title_hl }

	-- Author with dynamic highlight
	if item.author then
		ret[#ret + 1] = { " " }
		local author_hl = ui_hl.author or "SnacksTeaGray"
		ret[#ret + 1] = { icons.user, author_hl }
		ret[#ret + 1] = { item.author, author_hl }
	end

	-- Assignee (if available and different from author)
	if item.assignee and item.assignee ~= item.author then
		ret[#ret + 1] = { " " }
		local assignee_hl = ui_hl.assignee or "Function"
		ret[#ret + 1] = { "→", assignee_hl }
		ret[#ret + 1] = { item.assignee, assignee_hl }
	end

	-- Labels with dynamic highlight
	if item.labels and #item.labels > 0 then
		for _, label in ipairs(item.labels) do
			ret[#ret + 1] = { " " }
			local color = label.color or "888888"
			local badge = Snacks.picker.highlight.badge(label.name, "#" .. color)
			vim.list_extend(ret, badge)
		end
	end

	return ret
end

---@param ctx snacks.picker.preview.ctx
function M.preview(ctx)
	local config = require("snacks.tea").config()
	local item = ctx.item

	-- Store the tea item for actions
	ctx.item.tea_item = item

	-- Set window and buffer options for preview
	item.wo = config.wo
	item.bo = config.bo

	-- Set preview title
	item.preview_title = ("%s PR #%s"):format(config.icons.logo, (item.number or item.index or ""))

	-- Make sure the item has a file field pointing to the URI
	if not item.file and item.uri then
		item.file = item.uri
	end

	return Snacks.picker.preview.file(ctx)
end

---@param opts { item: snacks.picker.tea.Item, ctx?: table, tea_actions?: table }
---@type snacks.picker.finder
function M.actions(opts, ctx)
	local item = opts.item
	-- Use pre-computed actions from tea_actions field (not opts.actions which has picker actions)
	local actions = opts.tea_actions or Actions.get_actions(item, opts.ctx or ctx)

	return function(cb)
		for name, action in pairs(actions) do
			-- Skip if action is a function (picker built-in action)
			if type(action) == "table" then
				cb({
					text = action.desc or name,
					name = name,
					action = action,
					icon = action.icon,
					priority = action.priority or 0,
				})
			end
		end
	end
end

---@type snacks.picker.format
function M.actions_format(item)
	local ret = {} ---@type snacks.picker.Highlight[]

	if item.icon then
		ret[#ret + 1] = { item.icon .. " ", "Special" }
	end
	ret[#ret + 1] = { item.text or item.name, "Normal" }

	return ret
end

---@param opts snacks.picker.tea.diff.Config
---@type snacks.picker.finder
function M.diff(opts, ctx)
	opts = opts or {}
	if not opts.pr then
		Snacks.notify.error("snacks.picker.tea.diff: `opts.pr` is required")
		return {}
	end

	local cwd = ctx:git_root()
	local Diff = require("snacks.picker.source.diff")

	---@async
	return function(cb)
		-- Fetch PR item to get branch and commit information
		local item = Api.get(
			{ type = "pr", repo = opts.repo, number = opts.pr },
			{ fields = { "base", "head" }, force = true }
		)

		if not item then
			Snacks.notify.error("Failed to fetch PR #" .. opts.pr)
			return
		end

		-- Check if we have the necessary branch information
		if not item.base or not item.head then
			Snacks.notify.error("PR #" .. opts.pr .. " missing branch information")
			return
		end

		local config = require("snacks.tea").config()
		local remote = config.tea.remote or "origin"

		-- Fetch the branches from remote
		-- This ensures we have the latest commits
		local Spawn = require("snacks.util.spawn")
		Spawn.new({
			cmd = "git",
			args = { "fetch", remote, item.base .. ":" .. item.base, item.head .. ":" .. item.head },
			cwd = cwd,
			timeout = 15000,
		}):wait()

		-- Use git diff with remote branch refs
		-- Use triple-dot syntax to show changes on head since it branched from base
		local base_ref = remote .. "/" .. item.base
		local head_ref = remote .. "/" .. item.head
		local args = { "diff", base_ref .. "..." .. head_ref }

		-- Parse diff using the built-in diff parser with git command
		Diff.diff(
			ctx:opts({
				cmd = "git",
				args = args,
				cwd = cwd,
				group = true, -- Group hunks by file
			}),
			ctx
		)(function(it)
			it.tea_item = item
			cb(it)
		end)
	end
end

---@param ctx snacks.picker.preview.ctx
function M.preview_diff(ctx)
	-- Use the built-in diff preview
	Snacks.picker.preview.diff(ctx)

	-- Store tea item data for actions
	local item = ctx.item.tea_item ---@type snacks.picker.tea.Item?
	if item then
		vim.b[ctx.buf].snacks_tea = {
			repo = item.repo,
			type = item.type,
			number = item.number,
		}
	end
end

return M
