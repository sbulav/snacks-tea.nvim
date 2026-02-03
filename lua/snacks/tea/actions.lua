local Api = require("snacks.tea.api")
local config = require("snacks.tea").config()

local M = {}

---@class snacks.tea.actions: {[string]:snacks.tea.Action}
M.actions = setmetatable({}, {
	__index = function(_, key)
		if type(key) ~= "string" then
			return nil
		end
		local action = M.cli_actions[key]
		if action then
			local ret = M.cli_action(action)
			rawset(M.actions, key, ret)
			return ret
		end
	end,
})

-- Action to show available actions (similar to gh plugin)
M.actions.tea_actions = {
	desc = "Show available actions",
	action = function(item, ctx)
		if ctx.action and ctx.action.cmd then
			return Snacks.picker.actions.jump(ctx.picker, item, ctx.action)
		end
		local actions = M.get_actions(item, ctx)
		actions.tea_actions = nil -- remove this action

		-- Get layout config for actions
		local tea_config = require("snacks.tea").config()
		local actions_layout = tea_config.layout and tea_config.layout.actions or {}
		
		-- Use direct config instead of string lookup
		local source = require("snacks.picker.source.tea")
		local picker_opts = {
			title = "  Forgejo Actions",
			finder = source.actions,
			format = source.actions_format,
			sort = { fields = { "priority:desc", "idx" } },
			item = item,
			ctx = ctx,
			tea_actions = actions, -- Use custom field name to avoid conflict with picker's actions
			win = {
				preview = {
					width = 0, -- Hide preview by setting width to 0
				},
			},
			layout = {
				config = function(layout)
					-- Hide preview window
					for _, box in ipairs(layout.layout) do
						if box.win == "preview" then
							box.width = 0
							box.height = 0
						end
						if box.win == "list" and not box.height then
							box.height = math.max(math.min(vim.tbl_count(actions), vim.o.lines * 0.8 - 10), 3)
						end
					end
				end,
			},
			confirm = function(picker, it, action)
				if not it then
					return
				end
				ctx.action = action
				if ctx.picker then
					ctx.picker.visual = ctx.picker.visual or picker.visual or nil
					ctx.picker:focus()
				end
				it.action.action(item, ctx)
				picker:close()
			end,
		}
		
		-- Merge with actions layout config
		picker_opts = vim.tbl_deep_extend("force", picker_opts, actions_layout)
		
		Snacks.picker.pick(picker_opts)
	end,
}

-- View PR diff
M.actions.tea_diff = {
	desc = "View PR diff",
	icon = " ",
	priority = 100,
	type = "pr",
	title = "View diff for PR #{number}",
	action = function(item, ctx)
		if not item then
			return
		end
		-- Get the config function and call it to get base config
		local config_module = require("snacks.picker.config.tea")
		local base_config = type(config_module.tea_diff) == "function" 
			and config_module.tea_diff() 
			or config_module.tea_diff
		
		-- Merge with item-specific options
		local picker_config = vim.tbl_deep_extend("force", base_config or {}, {
			show_delay = 0,
			repo = item.repo,
			pr = item.number,
		})
		Snacks.picker(picker_config)
	end,
}

-- Open in buffer
M.actions.tea_open = {
	desc = "Open in buffer",
	icon = " ",
	priority = 100,
	title = "Open PR #{number} in buffer",
	action = function(item, ctx)
		if ctx.picker then
			return Snacks.picker.actions.jump(ctx.picker, item, ctx.action)
		end
	end,
}

-- Browse in web browser
M.actions.tea_browse = {
	desc = "Open in web browser",
	title = "Open PR #{number} in web browser",
	icon = " ",
	action = function(_, ctx)
		for _, item in ipairs(ctx.items) do
			-- Open URL in browser
			vim.ui.open(item.url)
			Snacks.notify.info(("Opened PR #%s in web browser"):format(item.number))
		end
		if ctx.picker then
			ctx.picker.list:set_selected() -- clear selection
		end
	end,
}

-- Yank URL to clipboard
M.actions.tea_yank = {
	desc = "Yank URL(s) to clipboard",
	icon = " ",
	action = function(_, ctx)
		if vim.fn.mode():find("^[vV]") and ctx.picker then
			ctx.picker.list:select()
		end
		---@param it snacks.picker.tea.Item
		local urls = vim.tbl_map(function(it)
			return it.url
		end, ctx.items)
		if ctx.picker then
			ctx.picker.list:set_selected() -- clear selection
		end
		local value = table.concat(urls, "\n")
		vim.fn.setreg(vim.v.register or "+", value, "l")
		Snacks.notify.info("Yanked " .. #urls .. " URL(s)")
	end,
}

---@type table<string, snacks.tea.cli.Action>
M.cli_actions = {
	tea_checkout = {
		cmd = "checkout",
		icon = " ",
		type = "pr",
		priority = 20,  -- High for quick access
		confirm = "Are you sure you want to checkout PR #{number}?",
		title = "Checkout PR #{number}",
		success = "Checked out PR #{number}",
	},
	tea_close = {
		cmd = "close",
		icon = config.icons.crossmark,
		title = "Close PR #{number}",
		success = "Closed PR #{number}",
		priority = 0,  -- Low priority
		enabled = function(item)
			return item.state == "open"
		end,
	},
	tea_reopen = {
		cmd = "reopen",
		icon = " ",
		title = "Reopen PR #{number}",
		success = "Reopened PR #{number}",
		priority = 0,  -- Low priority
		enabled = function(item)
			return item.state == "closed"
		end,
	},
	tea_merge = {
		cmd = "merge",
		icon = config.icons.pr.merged,
		type = "pr",
		success = "Merged PR #{number}",
		title = "Merge PR #{number}",
		priority = 10,  -- Medium-high for merges
		confirm = "Are you sure you want to merge PR #{number}?",
		enabled = function(item)
			return item.state == "open"
		end,
	},
	tea_approve = {
		cmd = "approve",
		icon = config.icons.checkmark,
		type = "pr",
		title = "Approve PR #{number}",
		success = "Approved PR #{number}",
		priority = 15,  -- High for approvals
		enabled = function(item)
			return item.state == "open"
		end,
	},
	tea_reject = {
		cmd = "reject",
		type = "pr",
		icon = " ",
		title = "Request changes on PR #{number}",
		success = "Requested changes on PR #{number}",
		priority = 12,  -- Medium-high for requests
		enabled = function(item)
			return item.state == "open"
		end,
	},
	tea_review = {
		cmd = "review",
		type = "pr",
		icon = " ",
		title = "Review PR #{number}",
		success = "Reviewed PR #{number}",
		priority = 8,  -- Medium for general reviews
		enabled = function(item)
			return item.state == "open"
		end,
	},
	tea_comment = {
		cmd = "comment",
		icon = " ",
		title = "Comment on PR #{number}",
		success = "Commented on PR #{number}",
		priority = 5,  -- Lower for comments
		edit = "body-file",
		no_type_prefix = true, -- tea comment doesn't use "pr" prefix
	},
}

---@param opts snacks.tea.cli.Action
function M.cli_action(opts)
	---@type snacks.tea.Action
	return setmetatable({
		desc = opts.desc or opts.title,
		---@type snacks.tea.action.fn
		action = function(item, ctx)
			M.run(item, opts, ctx)
		end,
	}, { __index = opts })
end

---@param str string
---@param ... table<string, any>
function M.tpl(str, ...)
	local data = { ... }
	return Snacks.picker.util.tpl(
		str,
		setmetatable({}, {
			__index = function(_, key)
				for _, d in ipairs(data) do
					if d[key] ~= nil then
						local ret = d[key]
						return ret == "pr" and "PR" or ret
					end
				end
			end,
		})
	)
end

---@param item snacks.picker.tea.Item
---@param ctx snacks.tea.action.ctx
function M.get_actions(item, ctx)
	local ret = {} ---@type table<string, snacks.tea.Action>
	local keys = vim.tbl_keys(M.actions) ---@type string[]
	vim.list_extend(keys, vim.tbl_keys(M.cli_actions))
	for _, name in ipairs(keys) do
		local action = M.actions[name]
		local enabled = action.type == nil or action.type == item.type
		enabled = enabled and (action.enabled == nil or action.enabled(item, ctx))
		if enabled then
			local a = setmetatable({}, { __index = action })
			local ca = M.cli_actions[name] or {}
			a.desc = a.title and M.tpl(a.title or name, item, ca) or a.desc
			a.name = name
			ret[name] = a
		end
	end
	return ret
end

--- Executes a tea cli action
---@param item snacks.picker.tea.Item
---@param action snacks.tea.cli.Action
---@param ctx snacks.tea.action.ctx
function M.run(item, action, ctx)
	local args = {}
	if action.cmd then
		if action.no_type_prefix then
			args = { action.cmd, tostring(item.number) }
		else
			args = { item.type, action.cmd, tostring(item.number) }
		end
	end
	vim.list_extend(args, action.args or {})

	---@type snacks.tea.cli.Action.ctx
	local cli_ctx = {
		item = item,
		args = args,
		opts = action,
		picker = ctx.picker,
		main = ctx.main,
	}

	if action.edit then
		return M.edit(cli_ctx)
	else
		return M._run(cli_ctx)
	end
end

--- Executes the action CLI command
---@param ctx snacks.tea.cli.Action.ctx
function M._run(ctx, force)
	if not force and ctx.opts.confirm then
		Snacks.picker.util.confirm(M.tpl(ctx.opts.confirm, ctx.item, ctx.opts), function()
			M._run(ctx, true)
		end)
		return
	end

	local spinner = require("snacks.picker.util.spinner").loading()
	local cb = function(proc, data)
		vim.schedule(function()
			spinner:stop()

			if not data then
				-- Error already handled by Api.cmd's error handler
				return
			end

			-- For PR creation, extract URL from output
			if ctx.opts.cmd == "create" then
				local pr_url = data:match("(https?://[^\n]+)")
				if pr_url then
					local pr_number = pr_url:match("/pulls?/(%d+)")
					local msg = ctx.opts.success or "Created pull request"
					if pr_number then
						msg = ("✓ Pull request #%s created"):format(pr_number)
					end
					Snacks.notify.info({
						msg,
						("URL: %s"):format(pr_url),
					}, { title = "Forgejo PR" })
				else
					Snacks.notify.info(ctx.opts.success or "Success", { title = "Forgejo Action" })
				end
			else
				-- success message for other actions
				if ctx.opts.success then
					Snacks.notify.info(M.tpl(ctx.opts.success, ctx.item, ctx.opts))
				end
			end

			-- refresh item and picker
			if ctx.opts.refresh ~= false and ctx.item and ctx.item.number then
				vim.schedule(function()
					Api.refresh(ctx.item)
					if ctx.picker and not ctx.picker.closed then
						ctx.picker:refresh()
						vim.cmd.startinsert()
					end
				end)
				if ctx.picker and not ctx.picker.closed then
					ctx.picker:focus()
				end
			end

			-- clean up scratch buffer
			if ctx.scratch then
				local buf = assert(ctx.scratch.buf)
				local fname = vim.api.nvim_buf_get_name(buf)
				ctx.scratch:on("WinClosed", function()
					vim.schedule(function()
						pcall(vim.api.nvim_buf_delete, buf, { force = true })
						os.remove(fname)
						os.remove(fname .. ".meta")
					end)
				end, { buf = true })
				ctx.scratch:close()
			end
		end)
	end

	Api.cmd(cb, {
		input = ctx.input,
		args = ctx.args,
		repo = ctx.item and ctx.item.repo or ctx.opts.repo,
		on_error = function()
			spinner:stop()
		end,
	})
end

--- Edit action body in scratch buffer
---@param ctx snacks.tea.cli.Action.ctx
function M.edit(ctx)
	---@param s? string
	local function tpl(s)
		return s and M.tpl(s, ctx.item, ctx.opts) or nil
	end

	local template = ctx.opts.template or ""

	-- Add frontmatter if fields are defined
	if not vim.tbl_isempty(ctx.opts.fields or {}) then
		local fm = { "---" }
		for _, f in ipairs(ctx.opts.fields) do
			local value = ctx.item and ctx.item[f.prop] or ""
			fm[#fm + 1] = ("%s: %s"):format(f.name, value)
		end
		fm[#fm + 1] = "---\n\n"
		template = table.concat(fm, "\n") .. template
	end

	local preview = ctx.picker and ctx.picker.preview and ctx.picker.preview.win:valid() and ctx.picker.preview.win
		or nil
	local actions = preview and preview.opts.actions or {}
	local parent = ctx.main or preview and preview.win or vim.api.nvim_get_current_win()

	-- Get scratch height from ui config or layout config
	local height = (config.layout and config.layout.create and config.layout.create.scratch and config.layout.create.scratch.height)
		or (config.ui and config.ui.scratch and config.ui.scratch.height)
		or 20
	local opts = Snacks.win.resolve({
		relative = "win",
		width = 0,
		backdrop = false,
		height = height,
		actions = {
			cycle_win = actions.cycle_win,
			preview_scroll_up = actions.preview_scroll_up,
			preview_scroll_down = actions.preview_scroll_down,
		},
		win = parent,
		wo = {
			winhighlight = "NormalFloat:Normal,FloatTitle:SnacksForgejoScratchTitle,FloatBorder:SnacksForgejoScratchBorder",
		},
		border = "top_bottom",
		row = function(win)
			local border = win:border_size()
			return win:parent_size().height - height - border.top - border.bottom
		end,
		on_win = function(win)
			if vim.api.nvim_win_is_valid(parent) then
				local parent_row = vim.api.nvim_win_call(parent, vim.fn.winline) ---@type number
				parent_row = parent_row + vim.wo[parent].scrolloff
				local row = vim.api.nvim_win_get_height(parent) - win:size().height
				if parent_row > row then
					vim.api.nvim_win_call(parent, function()
						vim.cmd(("normal! %d%s"):format(parent_row - row, Snacks.util.keycode("<C-e>")))
					end)
				end
			end
			vim.g.snacks_picker_cycle_win = win.win
			vim.schedule(function()
				vim.cmd.startinsert()
			end)
		end,
		footer_keys = { "<c-s>", "R" },
		keys = {
			submit = {
				"<c-s>",
				function(win)
					ctx.scratch = win
					M.submit(ctx)
				end,
				desc = "Submit",
				mode = { "n", "i" },
			},
		},
	}, preview and {
		keys = {
			["<a-w>"] = { "cycle_win", mode = { "i", "n" } },
			["<c-b>"] = { "preview_scroll_up", mode = { "i", "n" } },
			["<c-f>"] = { "preview_scroll_down", mode = { "i", "n" } },
		},
	} or nil)

	Snacks.scratch({
		ft = "markdown",
		icon = config.icons.logo,
		name = tpl(ctx.item.title or ctx.opts.title or "{cmd} PR #{number}"),
		template = tpl(template),
		filekey = {
			cwd = true,
			branch = true,
			count = false,
			id = tpl("{repo}/pr/{cmd}"),
		},
		win = opts,
	})
end

--- Parses frontmatter fields from body and extracts them
---@param body string
---@param ctx snacks.tea.cli.Action.ctx
---@return string? body The body without frontmatter, or nil if parsing failed
function M.parse(body, ctx)
	if not ctx.opts.fields then
		return body
	end

	local fields = {} ---@type table<string, table>
	for _, f in ipairs(ctx.opts.fields) do
		fields[f.name] = f
	end

	local values = {} ---@type table<string, string>
	--- parse markdown frontmatter for fields
	body = body:gsub("^(%-%-%-\n.-\n%-%-%-\n%s*)", function(fm)
		fm = fm:gsub("^%-%-%-\n", ""):gsub("\n%-%-%-\n%s*$", "") --[[@as string]]
		local lines = vim.split(fm, "\n")
		for _, line in ipairs(lines) do
			local field, value = line:match("^(%w+):%s*(.-)%s*$")
			if field and fields[field] then
				values[field] = value
			elseif field then
				Snacks.notify.warn(("Unknown field `%s` in frontmatter"):format(field))
			end
		end
		return ""
	end) --[[@as string]]

	for _, field in ipairs(ctx.opts.fields) do
		local value = values[field.name]
		if value and value ~= "" then
			vim.list_extend(ctx.args, { "--" .. field.arg, value })
		else
			Snacks.notify.error(("Missing required field `%s` in frontmatter"):format(field.name))
			return nil
		end
	end

	return body
end

--- Submit edited body
---@param ctx snacks.tea.cli.Action.ctx
function M.submit(ctx)
	local edit = assert(ctx.opts.edit, "Submit called for action that doesn't need edit?")
	local win = assert(ctx.scratch, "Submit not called from scratch window?")
	ctx = setmetatable({
		args = vim.deepcopy(ctx.args),
	}, { __index = ctx })

	local body = win:text()

	-- Parse frontmatter if fields are defined
	if ctx.opts.fields then
		body = M.parse(body, ctx)
		if not body then
			return -- error already shown in M.parse
		end
	end

	-- Clean up empty lines at start/end
	body = body:gsub("^%s+", ""):gsub("%s+$", "")

	if body:find("%S") then
		if edit == "body-file" then
			-- For comment command, body is a positional argument
			-- For pr create, use --description flag
			if ctx.opts.cmd == "comment" then
				vim.list_extend(ctx.args, { body })
			else
				vim.list_extend(ctx.args, { "--description", body })
			end
		else
			vim.list_extend(ctx.args, { "--" .. edit, body })
		end
	end

	vim.cmd.stopinsert()
	vim.schedule(function()
		M._run(ctx)
	end)
end

--- Creates a PR creation action with proper context
---@param item table Item data with branch info
---@return snacks.tea.cli.Action
function M.create_pr_action(item)
	return {
		cmd = "create",
		icon = " ",
		title = "Create Pull Request",
		success = "Created pull request",
		edit = "body-file",
		fields = {
			{ arg = "title", prop = "title", name = "Title" },
			{ arg = "base", prop = "base", name = "Base" },
		},
		template = "",
		args = { "--allow-maintainer-edits" },
	}
end

return M
