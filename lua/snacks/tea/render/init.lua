---@class snacks.tea.render
local M = {}

---@param buf number
---@param item snacks.picker.tea.Item
---@param opts snacks.tea.Config
function M.render(buf, item, opts)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local lines = {} ---@type string[]
	local config = opts or {}

	-- Header
	local state_icon = config.icons.pr[item.state] or config.icons.pr.other
	table.insert(lines, string.format("# %s PR #%d: %s", state_icon, item.number, item.title))
	table.insert(lines, "")

	-- Metadata
	table.insert(lines, string.format("**Author:** %s", item.author or "Unknown"))
	table.insert(lines, string.format("**State:** %s", item.state or "unknown"))
	table.insert(lines, string.format("**Base:** `%s` → **Head:** `%s`", item.base or "?", item.head or "?"))

	if item.created_at then
		table.insert(lines, string.format("**Created:** %s", item.created_at))
	end
	if item.updated_at then
		table.insert(lines, string.format("**Updated:** %s", item.updated_at))
	end

	if item.labels and #item.labels > 0 then
		local label_names = vim.tbl_map(function(l)
			return l.name
		end, item.labels)
		table.insert(lines, string.format("**Labels:** %s", table.concat(label_names, ", ")))
	end

	table.insert(lines, "")
	table.insert(lines, "---")
	table.insert(lines, "")

	-- Body
	if item.body and item.body ~= "" then
		table.insert(lines, "## Description")
		table.insert(lines, "")
		for line in item.body:gmatch("[^\r\n]+") do
			table.insert(lines, line)
		end
		table.insert(lines, "")
	end

	-- Comments
	if item.comments and type(item.comments) == "table" and #item.comments > 0 then
		table.insert(lines, "")
		table.insert(lines, "---")
		table.insert(lines, "")
		table.insert(lines, "## 💬 Comments")
		table.insert(lines, "")

		for i, comment in ipairs(item.comments) do
			-- Comment header with visual separator
			table.insert(lines, string.format("### %s **@%s** · %s", config.icons.user, comment.user, comment.created))
			table.insert(lines, "")

			-- Comment body
			for line in comment.body:gmatch("[^\r\n]+") do
				table.insert(lines, line)
			end

			-- Add spacing between comments (but not after the last one)
			if i < #item.comments then
				table.insert(lines, "")
				table.insert(lines, "")
			end
		end
	end

	-- Diff (if available)
	if item.diff and item.diff ~= "" and not opts.partial then
		table.insert(lines, "---")
		table.insert(lines, "")
		table.insert(lines, "## Diff")
		table.insert(lines, "")
		table.insert(lines, "```diff")
		for line in item.diff:gmatch("[^\r\n]+") do
			table.insert(lines, line)
		end
		table.insert(lines, "```")
		table.insert(lines, "")
	end

	-- Set buffer content
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	vim.api.nvim_buf_set_option(buf, "modified", false)
end

return M
