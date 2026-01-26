---@class snacks.tea.item
local M = {}
M.__index = M

---@param item snacks.tea.PR|snacks.picker.tea.Item
---@return boolean
function M.is(item)
	return getmetatable(item) == M
end

---@param item snacks.tea.PR|snacks.picker.tea.Item
---@return string
function M.get_repo(url)
	-- Extract owner/repo from URL like https://gitea.example.com/owner/repo/pulls/123
	local owner, repo = url:match("https?://[^/]+/([^/]+)/([^/]+)")
	return owner and repo and (owner .. "/" .. repo) or ""
end

---@param item snacks.tea.api.View
---@return string
function M.to_uri(item)
	return ("tea://%s/%s/%d"):format(item.repo, item.type, item.number)
end

---@param item snacks.tea.PR
---@param opts table
---@return snacks.picker.tea.Item
function M.new(item, opts)
	opts = opts or {}

	-- Convert tea CLI field names to our internal structure
	local ret = {
		-- Core fields
		index = item.index,
		number = item.index,
		title = item.title,
		state = item.state,
		author = item.author,
		url = item.url,
		body = item.body,

		-- Branch info
		base = item.base,
		base_commit = item["base-commit"] or item.base_commit,
		head = item.head,
		head_commit = item["head-commit"] or item.head_commit,

		-- Metadata
		created_at = item.created or item.created_at,
		updated_at = item.updated or item.updated_at,
		deadline = item.deadline,

		-- PR specific
		mergeable = item.mergeable,
		assignees = item.assignees,
		milestone = item.milestone,
		labels = item.labels,
		comments = item.comments,

		-- Diff data
		diff = item.diff,
		patch = item.patch,

		-- Internal fields
		type = "pr",
		repo = item.repo or M.get_repo(item.url),
		dirty = false,
	}

	ret.uri = M.to_uri(ret)
	ret.file = ret.uri -- Set file to URI so picker can preview it

	-- Apply transform if provided
	if opts.transform then
		ret = opts.transform(ret)
	end

	return setmetatable(ret, M)
end

---@param fields string[]
---@return string[]
function M:need(fields)
	local ret = {} ---@type string[]
	for _, field in ipairs(fields) do
		if self[field] == nil then
			ret[#ret + 1] = field
		end
	end
	return ret
end

---@param data snacks.tea.PR
---@param fields string[]
function M:update(data, fields)
	for _, field in ipairs(fields) do
		-- Handle field name translation (tea uses hyphens, we use underscores)
		local tea_field = field:gsub("_", "-")
		if data[field] ~= nil then
			self[field] = data[field]
		elseif data[tea_field] ~= nil then
			self[field] = data[tea_field]
		end
	end
end

return M
