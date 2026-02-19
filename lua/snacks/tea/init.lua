---@class snacks.tea
---@field api snacks.tea.api
---@field item snacks.picker.tea.Item
local M = setmetatable({}, {
	---@param M snacks.tea
	__index = function(M, k)
		if vim.tbl_contains({ "api" }, k) then
			M[k] = require("snacks.tea." .. k)
		end
		return rawget(M, k)
	end,
})

M.meta = {
	desc = "Tea CLI integration for Forgejo/Gitea",
	needs_setup = false,
	version = "0.2.0",
}

---@class snacks.tea.Config
local defaults = {
	--- Tea CLI configuration
	---@type snacks.tea.tea.Config
	tea = {
		cmd = "tea",
		login = nil,
		remote = "origin",
		timeout = 30000, -- 30 seconds default timeout
	},

  --- Keymaps for Forgejo buffers
  ---@type table<string, snacks.tea.Keymap|false>?
  -- stylua: ignore
  keys = {
    select   = { "<cr>", "tea_actions" , desc = "Select Action" },
    diff     = { "d"   , "tea_diff"    , desc = "View Diff" },
    checkout = { "c"   , "tea_checkout", desc = "Checkout PR" },
    approve  = { "A"   , "tea_approve" , desc = "Approve PR" },
    comment  = { "a"   , "tea_comment" , desc = "Add Comment" },
    close    = { "x"   , "tea_close"   , desc = "Close" },
    reopen   = { "o"   , "tea_reopen"  , desc = "Reopen" },
    refresh  = { "r"   , function(item, buf)
      if buf and buf.update then
        buf:update()
      end
    end, desc = "Refresh PR" },
  },

	--- UI configuration
	ui = {
		--- Highlight groups for different PR elements
		highlights = {
			pr_state = {
				open = "DiagnosticOk",
				closed = "DiagnosticError",
				merged = "DiagnosticInfo",
				draft = "Comment",
			},
			author = "Identifier",
			assignee = "Function",
			label = "Special",
			branch = "@markup.link",
			number = "Number",
			title = "Normal",
			description = "Normal",
			comment_header = "DiagnosticInfo",
			comment_body = "Normal",
			date = "Comment",
		},
		--- Scratch window dimensions
		scratch = {
			width = 160,
			height = 20,
		},
	},

	--- Buffer display configuration
	buffer = {
		--- Window options for PR buffers
		---@type vim.wo|{}
		wo = {
			breakindent = true,
			wrap = true,
			showbreak = "",
			linebreak = true,
			number = false,
			relativenumber = false,
			foldexpr = "v:lua.vim.treesitter.foldexpr()",
			foldmethod = "expr",
			foldlevel = 99, -- Show all folds expanded by default
			concealcursor = "n",
			conceallevel = 2,
			list = false,
			signcolumn = "no",
			winhighlight = Snacks.util.winhl({
				Normal = "SnacksTeaNormal",
				NormalFloat = "SnacksTeaNormalFloat",
				FloatBorder = "SnacksTeaBorder",
				FloatTitle = "SnacksTeaTitle",
				FloatFooter = "SnacksTeaFooter",
			}),
		},
		--- Buffer options
		---@type vim.bo|{}
		bo = {},
		--- Display options
		display = {
			show_comments = true,
			show_diff = true,
			show_reviews = true,
			show_checks = true,
			fold_comments = false, -- Auto-fold comment threads
			fold_diff = false, -- Auto-fold diff section
		},
		--- Optional integrations
		integrations = {
			render_markdown = true, -- Auto-detect render-markdown.nvim
		},
	},

	--- Layout configuration for different picker types
	layout = {
		pr_list = nil, -- Use default
		actions = {
			preset = "select",
			layout = { max_width = 60, max_height = 20 },
		},
		diff = nil, -- Use default
		create = {
			scratch = { width = 160, height = 25 },
		},
	},

	diff = {
		min = 4, -- minimum number of lines changed to show diff
		wrap = 80, -- wrap diff lines at this length
	},

-- stylua: ignore
   icons = {
     logo = " ",
     user= " ",
     checkmark = " ",
     crossmark = " ",
     block = "■",
     file = " ",
    checks = {
      pending = " ",
      success = " ",
      failure = "",
      skipped = " ",
    },
    pr = {
      open   = " ",
      closed = " ",
      merged = " ",
      draft  = " ",
      other  = " ",
    },
    review = {
      approved           = " ",
      changes_requested  = " ",
      commented          = " ",
      dismissed          = " ",
      pending            = " ",
    },
    merge_status = {
      clean    = " ",
      dirty    = " ",
      blocked  = " ",
      unstable = " "
    },
     reactions = {
       thumbs_up   = "👍",
       thumbs_down = "👎",
       eyes        = "👀",
       confused    = "😕",
       heart       = "❤️",
       hooray      = "🎉",
       laugh       = "😄",
       rocket      = "🚀",
     },
   },
	gh_style = {
		enabled = true,
	},
}

-- Set up highlight groups (similar to gh plugin)
local function diff_linenr(hl)
	local fg = Snacks.util.color({ hl, "SnacksTeaNormalFloat", "Normal" })
	local bg = Snacks.util.color({ hl, "SnacksTeaNormalFloat", "Normal" }, "bg")
	bg = bg or vim.o.background == "dark" and "#1e1e1e" or "#f5f5f5"
	return {
		fg = fg,
		bg = Snacks.util.blend(fg, bg, 0.1),
	}
end

Snacks.util.set_hl({
	Normal = "NormalFloat",
	NormalFloat = "NormalFloat",
	Border = "FloatBorder",
	Title = "FloatTitle",
	ScratchTitle = "Number",
	ScratchBorder = "Number",
	Footer = "FloatFooter",
	Number = "Number",
	Green = { fg = "#28a745" },
	Purple = { fg = "#6f42c1" },
	Gray = { fg = "#6a737d" },
	Red = { fg = "#d73a49" },
	Branch = "@markup.link",
	PrOpen = "SnacksTeaGreen",
	PrClosed = "SnacksTeaRed",
	PrMerged = "SnacksTeaPurple",
	PrDraft = "SnacksTeaGray",
	Label = "@property",
	Delim = "@punctuation.delimiter",
	UserBadge = "DiagnosticInfo",
	AuthorBadge = "DiagnosticWarn",
	OwnerBadge = "DiagnosticError",
	BotBadge = { fg = Snacks.util.color({ "NonText", "SignColumn", "FoldColumn" }) },
	ReactionBadge = "Special",
	AssocBadge = {},
	StatBadge = "Special",
	PrClean = "DiagnosticInfo",
	PrUnstable = "DiagnosticWarn",
	PrDirty = "DiagnosticError",
	PrBlocked = "DiagnosticError",
	Additions = "SnacksTeaGreen",
	Deletions = "SnacksTeaRed",
	CheckPending = "DiagnosticWarn",
	CheckSuccess = "SnacksTeaGreen",
	CheckFailure = "SnacksTeaRed",
	CheckSkipped = "SnacksTeaStat",
	ReviewApproved = "SnacksTeaGreen",
	ReviewChangesRequested = "DiagnosticError",
	ReviewCommented = {},
	ReviewPending = "DiagnosticWarn",
	CommentAction = "@property",
	DiffHeader = "DiagnosticVirtualTextInfo",
	DiffAdd = "DiffAdd",
	DiffDelete = "DiffDelete",
	DiffContext = "DiffChange",
	DiffAddLineNr = diff_linenr("DiffAdd"),
	DiffDeleteLineNr = diff_linenr("DiffDelete"),
	DiffContextLineNr = diff_linenr("DiffChange"),
	Stat = { fg = Snacks.util.color("SignColumn") },
	SuggestionBadge = "Special",
}, { default = true, prefix = "SnacksTea" })

M._config = nil ---@type snacks.tea.Config?
local did_setup = false

---@param opts? snacks.picker.tea.Config
function M.pr(opts)
	opts = opts or {}

	-- Ensure setup is called to register autocmds
	M.setup()

	-- Check if we're in a git repository
	local Git = require("snacks.tea.git")
	local git_root = Git.get_root()
	if not git_root then
		Snacks.notify.error({
			"Not in a git repository",
			"",
			"Forgejo PR picker requires:",
			"  1. Being in a git repository",
			"  2. Having a Forgejo/Gitea remote",
			"  3. Tea CLI configured (run: tea login add)",
		}, { title = "Tea PR Picker" })
		return
	end

	-- Check if this is a GitHub remote
	if Git.is_github_remote() then
		Snacks.notify.warn({
			"This is a GitHub repository!",
			"",
			"Tea CLI only works with Forgejo/Gitea instances.",
			"For GitHub PRs, use snacks.gh instead:",
			"  :lua Snacks.gh.pr()",
		}, { title = "Tea PR Picker" })
		return
	end

	-- Check if tea is available (silent mode)
	if not M.health_check({ silent = true }) then
		return
	end

	-- If picker sources are registered, use them
	local has_registered = Snacks.picker
		and Snacks.picker.config
		and Snacks.picker.config.defaults
		and Snacks.picker.config.defaults.tea_pr

	if has_registered then
		return Snacks.picker.tea_pr(opts)
	end

	-- Otherwise, call picker directly with our custom config
	local source = require("snacks.picker.source.tea")
	local picker_opts = {
		title = "  Forgejo Pull Requests",
		finder = source.pr,
		format = source.format,
		preview = source.preview,
		sort = { fields = { "score:desc", "idx" } },
		supports_live = true,
		live = true,
	}

	-- Merge user opts
	picker_opts = vim.tbl_deep_extend("force", picker_opts, opts)

	return Snacks.picker(picker_opts)
end

---@class snacks.tea.CreatePROptions
---@field title? string PR title
---@field description? string PR description/body
---@field base? string Target branch (defaults to repo's default branch)
---@field head? string Source branch (defaults to current branch)

---@param opts? snacks.tea.CreatePROptions
function M.pr_create(opts)
	opts = opts or {}

	-- Ensure setup is called
	M.setup()

	-- Check if we're in a git repository
	local Git = require("snacks.tea.git")
	local git_root = Git.get_root()
	if not git_root then
		Snacks.notify.error({
			"Not in a git repository",
			"",
			"Forgejo PR creation requires:",
			"  1. Being in a git repository",
			"  2. Having a Forgejo/Gitea remote",
			"  3. Tea CLI configured (run: tea login add)",
		}, { title = "Tea PR Create" })
		return
	end

	-- Check if this is a GitHub remote
	if Git.is_github_remote() then
		Snacks.notify.warn({
			"This is a GitHub repository!",
			"",
			"Tea CLI only works with Forgejo/Gitea instances.",
			"For GitHub PR creation, use snacks.gh instead:",
			"  :lua Snacks.gh.pr_create()",
		}, { title = "Tea PR Create" })
		return
	end

	-- Check if tea is available (silent mode)
	if not M.health_check({ silent = true }) then
		return
	end

	-- Get git information
	local git = require("snacks.tea.git")
	local current_branch = git.get_current_branch()
	local default_branch = git.get_default_branch() or "main"

	if not current_branch then
		Snacks.notify.error("Could not determine current branch", { title = "Tea PR Create" })
		return
	end

	-- Create action context with branch info
	local actions = require("snacks.tea.actions")
	local action = actions.create_pr_action()

	-- Set up item with branch defaults
	local item = {
		title = opts.title or current_branch,
		base = opts.base or default_branch,
	}

	-- Context for running the action
	local ctx = {
		item = item,
		args = { "pr", "create", "--allow-maintainer-edits" },
		opts = action,
	}

	-- Open scratch buffer for editing
	actions.edit(ctx)
end

---@private
local function validate_config(config)
	local errors = {}

	-- Validate tea.cmd
	if config.tea then
		if config.tea.cmd and type(config.tea.cmd) ~= "string" then
			table.insert(errors, "tea.cmd must be a string, got: " .. type(config.tea.cmd))
		end
		if config.tea.remote and type(config.tea.remote) ~= "string" then
			table.insert(errors, "tea.remote must be a string, got: " .. type(config.tea.remote))
		end
		if config.tea.login and type(config.tea.login) ~= "string" then
			table.insert(errors, "tea.login must be a string, got: " .. type(config.tea.login))
		end
		if config.tea.timeout and type(config.tea.timeout) ~= "number" then
			table.insert(errors, "tea.timeout must be a number, got: " .. type(config.tea.timeout))
		elseif config.tea.timeout and config.tea.timeout < 1000 then
			table.insert(errors, "tea.timeout should be at least 1000ms, got: " .. config.tea.timeout)
		end
	end

	-- Validate diff config
	if config.diff then
		if config.diff.min and type(config.diff.min) ~= "number" then
			table.insert(errors, "diff.min must be a number, got: " .. type(config.diff.min))
		end
		if config.diff.wrap and type(config.diff.wrap) ~= "number" then
			table.insert(errors, "diff.wrap must be a number, got: " .. type(config.diff.wrap))
		end
	end

	-- Validate ui.scratch
	if config.ui and config.ui.scratch then
		if config.ui.scratch.width and type(config.ui.scratch.width) ~= "number" then
			table.insert(errors, "ui.scratch.width must be a number, got: " .. type(config.ui.scratch.width))
		end
		if config.ui.scratch.height and type(config.ui.scratch.height) ~= "number" then
			table.insert(errors, "ui.scratch.height must be a number, got: " .. type(config.ui.scratch.height))
		end
	end

	-- Validate keys format
	if config.keys then
		for name, km in pairs(config.keys) do
			if km ~= false then
				if type(km) ~= "table" then
					table.insert(errors, ("keys.%s must be a table or false, got: %s"):format(name, type(km)))
				elseif not km[1] then
					table.insert(errors, ("keys.%s missing lhs (first element)"):format(name))
				end
			end
		end
	end

	-- Report errors
	if #errors > 0 then
		Snacks.notify.error({
			"Invalid snacks-tea.nvim configuration:",
			"",
			unpack(vim.tbl_map(function(e) return "  - " .. e end, errors)),
		}, { title = "Tea Config" })
		return false
	end

	return true
end

---@private
function M.config()
	if not M._config then
		local cfg = Snacks.config.get("tea", defaults)
		validate_config(cfg)
		M._config = cfg
	end
	return M._config
end

---@private
---@param ev? vim.api.keyset.create_autocmd.callback_args
function M.setup(ev)
	if did_setup then
		return
	end
	did_setup = true

	-- Register picker sources, formatters, and previews if picker is available
	if Snacks.picker and Snacks.picker.config and Snacks.picker.config.defaults then
		vim.schedule(function()
			local ok, tea_source = pcall(require, "snacks.picker.source.tea")
			if ok then
				-- Register formatters
				Snacks.picker.format = Snacks.picker.format or {}
				Snacks.picker.format.tea_format = tea_source.format
				Snacks.picker.format.tea_actions_format = tea_source.actions_format

				-- Register preview
				Snacks.picker.preview = Snacks.picker.preview or {}
				Snacks.picker.preview.tea_preview = tea_source.preview
				Snacks.picker.preview.tea_preview_diff = tea_source.preview_diff

				-- Register finders
				Snacks.picker.finder = Snacks.picker.finder or {}
				Snacks.picker.finder.tea_pr = tea_source.pr
				Snacks.picker.finder.tea_actions = tea_source.actions
				Snacks.picker.finder.tea_diff = tea_source.diff

				-- Register actions
				local actions_ok, actions_mod = pcall(require, "snacks.tea.actions")
				if actions_ok and actions_mod.actions then
					for action_name, _ in pairs(actions_mod.actions) do
						if tea_source.actions[action_name] then
							Snacks.picker.actions[action_name] = tea_source.actions[action_name]
						end
					end
				end

				-- Register picker configuration
				local config_ok, tea_config = pcall(require, "snacks.picker.config.tea")
				if config_ok then
					for name, config in pairs(tea_config) do
						-- Handle both function and table configs
						if type(config) == "function" then
							Snacks.picker.config.defaults[name] = config()
						else
							Snacks.picker.config.defaults[name] = config
						end
					end
				end
			end
		end)
	end

	require("snacks.tea.buf").setup()
	if ev then
		vim.schedule(function()
			require("snacks.tea.buf").attach(ev.buf)
		end)
	end

	-- Create user commands
	vim.api.nvim_create_user_command("TeaPR", function(opts)
		local args = {}
		if opts.args ~= "" then
			-- Parse args like state=closed or limit=50
			for pair in opts.args:gmatch("[^%s]+") do
				local key, value = pair:match("([^=]+)=([^=]+)")
				if key and value then
					-- Convert numbers
					if tonumber(value) then
						args[key] = tonumber(value)
					else
						args[key] = value
					end
				end
			end
		end
		M.pr(args)
	end, {
		nargs = "*",
		desc = "List PRs via Tea CLI (Forgejo/Gitea)",
	})

	vim.api.nvim_create_user_command("TeaPRCreate", function(opts)
		local args = {}
		if opts.args ~= "" then
			-- Parse simple args like base=develop
			for pair in opts.args:gmatch("[^%s]+") do
				local key, value = pair:match("([^=]+)=([^=]+)")
				if key and value then
					args[key] = value
				end
			end
		end
		M.pr_create(args)
	end, {
		nargs = "*",
		desc = "Create PR via Tea CLI (Forgejo/Gitea)",
	})

	vim.api.nvim_create_user_command("TeaHealth", function()
		M.health_check({ verbose = true })
	end, {
		nargs = 0,
		desc = "Check Tea CLI health (Forgejo/Gitea)",
	})
end

--- Check if tea CLI is available
---@param opts? { verbose?: boolean, silent?: boolean }
---@return boolean
function M.health_check(opts)
	-- Default to verbose unless explicitly silenced
	if opts == nil then
		opts = { verbose = true }
	elseif opts.verbose == nil and not opts.silent then
		opts.verbose = true
	end
	local config = M.config()
	local tea_cmd = config.tea.cmd or "tea"

	if vim.fn.executable(tea_cmd) == 0 then
		local msg = {
			("Tea CLI not found: %s"):format(tea_cmd),
			"Install it from https://gitea.com/gitea/tea",
		}
		Snacks.notify.error(msg, { title = "Tea Health Check" })
		if opts.verbose then
			vim.print(table.concat(msg, "\n"))
		end
		return false
	end

	-- Get tea version to verify it works
	local version = vim.fn.system(tea_cmd .. " --version 2>&1")
	-- Remove ANSI color codes and clean up
	local version_clean = version:gsub("\27%[[0-9;]*m", ""):gsub("\n", " "):gsub("%s+", " "):match("^%s*(.-)%s*$")

	if vim.v.shell_error == 0 then
		if opts.verbose then
			local msg = {
				("✓ Tea CLI found: %s"):format(tea_cmd),
				("✓ Version: %s"):format(version_clean),
				"",
				"Configuration:",
				("  Remote: %s"):format(config.tea.remote or "origin"),
				("  Login: %s"):format(config.tea.login or "auto-detect"),
			}
			Snacks.notify.info(msg, { title = "Tea Health Check" })
			vim.print(table.concat(msg, "\n"))
		end
	else
		local msg = {
			("✗ Tea CLI found but failed to execute: %s"):format(tea_cmd),
			("Error: %s"):format(version_clean),
			"Check your installation",
		}
		Snacks.notify.warn(msg, { title = "Tea Health Check" })
		if opts.verbose then
			vim.print(table.concat(msg, "\n"))
		end
		return false
	end

	return true
end

return M
