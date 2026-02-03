---@class snacks.tea.render
local M = {}

local H = Snacks.picker.highlight
local U = Snacks.picker.util
local Markdown = require("snacks.picker.util.markdown")

local ns = vim.api.nvim_create_namespace("snacks.tea.render")

-- Fallback for missing fields
local function safe_field(item, field, default)
  local val = item[field]
  if val == nil then return default or "" end
  if type(field) == "table" and type(val) == "string" then return {} end  -- Coerce string to table for arrays like labels
  return val
end

local function parse_iso_to_timestamp(iso_str)
  if not iso_str then return nil end
  -- Simple ISO 8601 parser: YYYY-MM-DDTHH:MM:SSZ
  local year, mon, day, hour, min, sec = iso_str:match("(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):(%d%d)")
  if year then
    return os.time({
      year = tonumber(year),
      month = tonumber(mon),
      day = tonumber(day),
      hour = tonumber(hour),
      min = tonumber(min),
      sec = tonumber(sec),
      isdst = false,  -- Assume UTC
    })
  end
  return nil
end

local function time_prop(field)
  return {
    name = U.title(field),
    hl = function(item)
      local date_str = safe_field(item, field)
      if date_str == "" then return end
      local timestamp = parse_iso_to_timestamp(date_str)
      if timestamp then
        return { { U.reltime(timestamp), "SnacksPickerGitDate" } }
      else
        -- Fallback to raw string if parsing fails
        return { { date_str, "SnacksPickerGitDate" } }
      end
    end,
  }
end

M.props = {
	{
		name = "Status",
		hl = function(item, opts)
			local icons = opts.icons.pr
			local status = safe_field(item, "state", "other")
			local ret = {}
			local icon = icons[status:lower()] or icons.other or " "
			
			-- Use custom highlight from ui config if available
			local ui_hl = opts.ui and opts.ui.highlights or {}
			local hl = (ui_hl.pr_state and ui_hl.pr_state[status:lower()]) 
				or "SnacksTeaPr" .. U.title(status)
			
			local text = icon .. U.title(status)
			H.extend(ret, H.badge(text, { bg = Snacks.util.color(hl), fg = "#ffffff" }))
			if safe_field(item, "base") ~= "" and safe_field(item, "head") ~= "" then
				ret[#ret + 1] = { " " }
				local branch_hl = ui_hl.branch or "SnacksTeaBranch"
				vim.list_extend(ret, {
					{ safe_field(item, "base"), branch_hl },
					{ " ← ", "SnacksTeaDelim" },
					{ safe_field(item, "head"), branch_hl },
				})
			end
			return ret
		end,
	},
	{
		name = "Author",
		hl = function(item, opts)
			local author = safe_field(item, "author", "Unknown")
			local ui_hl = opts.ui and opts.ui.highlights or {}
			local author_hl = ui_hl.author or "SnacksTeaUserBadge"
			return H.badge(opts.icons.user .. " " .. author, author_hl)
		end,
	},
	{
		name = "Assignee",
		hl = function(item, opts)
			local assignee = safe_field(item, "assignee", "")
			if assignee == "" or assignee == safe_field(item, "author", "") then
				return {}
			end
			local ui_hl = opts.ui and opts.ui.highlights or {}
			local assignee_hl = ui_hl.assignee or "Function"
			return H.badge("→ " .. assignee, assignee_hl)
		end,
	},
	time_prop("created_at"),
	time_prop("updated_at"),
	{
		name = "Labels",
		hl = function(item)
			local ret = {}
			local labels = safe_field(item, "labels", {})
			if type(labels) ~= "table" then labels = {} end
			for _, label in ipairs(labels) do
				local color = safe_field(label, "color", "888888")
				local name = safe_field(label, "name", "unknown")
				local badge = H.badge(name, "#" .. color)
				H.extend(ret, badge)
				ret[#ret + 1] = { " " }
			end
			return ret
		end,
	},
}

local function indent(lines, opts)
  local indent = { { "   ", "Normal" } }
  indent[#indent + 1] = {
    col = 0,
    virt_text = {
      { " ", "Normal" },
      { "┃", { "Normal", "@punctuation.definition.blockquote.markdown" } },
      { " ", "Normal" },
    },
    virt_text_pos = "overlay",
    hl_mode = "combine",
    virt_text_repeat_linebreak = true,
  }
  local first = opts.markdown == false and {} or {
    {
      col = 0,
      end_col = 3,
      conceal = "",
      priority = 1000,
    },
    { " * ", "Normal" },
  }
  local ret = {}
  for l, line in ipairs(lines) do
    local new = vim.deepcopy(l == 1 and first or indent)
    H.extend(new, line)
    ret[l] = new
  end
  return ret
end

function M.comment_header(comment, opts)
	local ret = {}
	local user = safe_field(comment, "user", "Unknown")
	local ui_hl = opts.ui and opts.ui.highlights or {}
	local header_hl = ui_hl.comment_header or "SnacksTeaUserBadge"
	H.extend(ret, H.badge(opts.icons.user .. " " .. user, header_hl))
	local created = safe_field(comment, "created", "Unknown")
	local date_hl = ui_hl.date or "SnacksPickerGitDate"
	ret[#ret + 1] = { " · " .. created, date_hl }
	return ret
end

function M.comment_body(comment)
  local body = safe_field(comment, "body", "")
  local ret = {}
  local md = vim.split(body, "\n", { plain = true })
  for _, l in ipairs(md) do
    ret[#ret + 1] = { { l } }
  end
  return ret
end

---@param buf number
---@param item snacks.picker.tea.Item
---@param opts snacks.tea.Config|{partial?:boolean}
function M.render(buf, item, opts)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	opts = opts or {}
	local lines = {} ---@type snacks.picker.Highlight[][]
	local ui_hl = opts.ui and opts.ui.highlights or {}
	local display = opts.buffer and opts.buffer.display or {}

	-- Header with state
	local state = safe_field(item, "state", "other")
	local state_icon = opts.icons.pr[state:lower()] or opts.icons.pr.other or " "
	local state_hl = (ui_hl.pr_state and ui_hl.pr_state[state:lower()]) 
		or "SnacksTeaPr" .. U.title(state)
	local number_hl = ui_hl.number or "Number"
	local title_hl = ui_hl.title or "Normal"
	local header = { 
		{ "# " }, 
		{ state_icon, state_hl }, 
		{ " PR #" .. safe_field(item, "number", "?") .. ": ", number_hl }, 
		{ safe_field(item, "title", "Untitled"), title_hl } 
	}
	lines[#lines + 1] = header
	lines[#lines + 1] = {}

	-- Metadata
	for _, prop in ipairs(M.props) do
		local value = prop.hl(item, opts)
		if value and #value > 0 then
			local line = { { prop.name, "SnacksTeaLabel" }, { ":", "SnacksTeaDelim" }, { " " } }
			H.extend(line, value)
			lines[#lines + 1] = line
		end
	end

	lines[#lines + 1] = {}

	lines[#lines + 1] = { { "---", "@punctuation.special.markdown" } }
	lines[#lines + 1] = {}

	-- Body
	if safe_field(item, "body", "") ~= "" then
		lines[#lines + 1] = { { "## Description" } }
		lines[#lines + 1] = {}
		local body = vim.split(safe_field(item, "body", ""), "\n")
		for _, l in ipairs(body) do
			lines[#lines + 1] = { { l } }
		end
		lines[#lines + 1] = {}
	end

	-- Comments (conditional rendering)
	local threads = safe_field(item, "comments", {})
	if type(threads) ~= "table" then threads = {} end
	if #threads > 0 and (display.show_comments ~= false) then
		-- Add fold marker for comments section
		local comments_header = { { "## 💬 Comments" } }
		if display.fold_comments then
			comments_header[#comments_header + 1] = { " {{{", "Comment" }
		end
		lines[#lines + 1] = comments_header
		lines[#lines + 1] = {}
		
		for _, comment in ipairs(threads) do
			local header = M.comment_header(comment, opts)
			lines[#lines + 1] = header
			local body_lines = M.comment_body(comment)
			body_lines = indent(body_lines, { markdown = true })
			vim.list_extend(lines, body_lines)
			lines[#lines + 1] = {}
		end
		
		-- Close fold marker
		if display.fold_comments then
			lines[#lines + 1] = { { "}}}", "Comment" } }
			lines[#lines + 1] = {}
		end
	end

	-- Diff (conditional rendering)
	if safe_field(item, "diff", "") ~= "" and not opts.partial and (display.show_diff ~= false) then
		lines[#lines + 1] = { { "---" } }
		lines[#lines + 1] = {}
		
		-- Add fold marker for diff section
		local diff_header = { { "## Diff" } }
		if display.fold_diff then
			diff_header[#diff_header + 1] = { " {{{", "Comment" }
		end
		lines[#lines + 1] = diff_header
		lines[#lines + 1] = {}
		
		lines[#lines + 1] = { { "```diff" } }
		local diff_lines = vim.split(safe_field(item, "diff", ""), "\n")
		for _, dl in ipairs(diff_lines) do
			local prefix = dl:match("^([ +%-])")
			local hl_group = prefix == "+" and "DiffAdd" or prefix == "-" and "DiffDelete" or "DiffText"
			lines[#lines + 1] = { { dl, hl_group } }
		end
		lines[#lines + 1] = { { "```" } }
		
		-- Close fold marker
		if display.fold_diff then
			lines[#lines + 1] = { { "}}}", "Comment" } }
		end
		lines[#lines + 1] = {}
	end

	local changed = H.render(buf, ns, lines)

	if changed then
		Markdown.render(buf, { bullets = false })
		
		-- Integrate render-markdown.nvim if enabled and available
		local integrations = opts.buffer and opts.buffer.integrations or {}
		if integrations.render_markdown and package.loaded["render-markdown"] then
			pcall(function()
				require("render-markdown").render({
					buf = buf,
					event = "TeaBuffer",
					config = { render_modes = true },
				})
			end)
		end
	end

	-- Apply Treesitter folding if available
	vim.schedule(function()
		for _, win in ipairs(vim.fn.win_findbuf(buf)) do
			vim.api.nvim_win_call(win, function()
				if vim.wo.foldmethod == "expr" then
					vim.wo.foldmethod = "expr"
				end
			end)
		end
	end)
end

return M