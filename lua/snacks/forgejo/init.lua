---@class snacks.forgejo
---@field api snacks.forgejo.api
---@field item snacks.picker.forgejo.Item
local M = setmetatable({}, {
  ---@param M snacks.forgejo
  __index = function(M, k)
    if vim.tbl_contains({ "api" }, k) then
      M[k] = require("snacks.forgejo." .. k)
    end
    return rawget(M, k)
  end,
})

M.meta = {
  desc = "Forgejo integration (via tea CLI)",
  needs_setup = false,
}

---@class snacks.forgejo.Config
local defaults = {
  --- Tea CLI configuration
  ---@type snacks.forgejo.tea.Config
  tea = {
    cmd = "tea",
    login = nil,
    remote = "origin",
  },

  --- Keymaps for Forgejo buffers
  ---@type table<string, snacks.forgejo.Keymap|false>?
  -- stylua: ignore
  keys = {
    select   = { "<cr>", "fg_actions" , desc = "Select Action" },
    checkout = { "c"   , "fg_checkout", desc = "Checkout PR" },
    approve  = { "A"   , "fg_approve" , desc = "Approve PR" },
    comment  = { "a"   , "fg_comment" , desc = "Add Comment" },
    close    = { "x"   , "fg_close"   , desc = "Close" },
    reopen   = { "o"   , "fg_reopen"  , desc = "Reopen" },
    refresh  = { "r"   , function(item, buf)
      if buf and buf.update then
        buf:update()
      end
    end, desc = "Refresh PR" },
  },

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
    concealcursor = "n",
    conceallevel = 2,
    list = false,
    winhighlight = Snacks.util.winhl({
      Normal = "SnacksForgejoNormal",
      NormalFloat = "SnacksForgejoNormalFloat",
      FloatBorder = "SnacksForgejoBorder",
      FloatTitle = "SnacksForgejoTitle",
      FloatFooter = "SnacksForgejoFooter",
    }),
  },

  ---@type vim.bo|{}
  bo = {},

  diff = {
    min = 4, -- minimum number of lines changed to show diff
    wrap = 80, -- wrap diff lines at this length
  },

  scratch = {
    height = 20, -- height of scratch window (increased for PR creation)
  },

  -- stylua: ignore
  icons = {
    logo = " ",
    user = " ",
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
      approved          = " ",
      changes_requested = " ",
      commented         = " ",
      dismissed         = " ",
      pending           = " ",
    },
    merge_status = {
      clean    = " ",
      dirty    = " ",
      blocked  = " ",
      unstable = " "
    },
  },
}

-- Set up highlight groups (similar to gh plugin)
local function diff_linenr(hl)
  local fg = Snacks.util.color({ hl, "SnacksForgejoNormalFloat", "Normal" })
  local bg = Snacks.util.color({ hl, "SnacksForgejoNormalFloat", "Normal" }, "bg")
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
  PrOpen = "SnacksForgejoGreen",
  PrClosed = "SnacksForgejoRed",
  PrMerged = "SnacksForgejoPurple",
  PrDraft = "SnacksForgejoGray",
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
  Additions = "SnacksForgejoGreen",
  Deletions = "SnacksForgejoRed",
  CheckPending = "DiagnosticWarn",
  CheckSuccess = "SnacksForgejoGreen",
  CheckFailure = "SnacksForgejoRed",
  CheckSkipped = "SnacksForgejoStat",
  ReviewApproved = "SnacksForgejoGreen",
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
}, { default = true, prefix = "SnacksForgejo" })

M._config = nil ---@type snacks.forgejo.Config?
local did_setup = false

---@param opts? snacks.picker.forgejo.Config
function M.pr(opts)
  opts = opts or {}
  
  -- Ensure setup is called to register autocmds
  M.setup()
  
  -- Check if we're in a git repository
  local git_root = Snacks.git.get_root(vim.uv.cwd() or ".")
  if not git_root then
    Snacks.notify.error({
      "Not in a git repository",
      "",
      "Forgejo PR picker requires:",
      "  1. Being in a git repository",
      "  2. Having a Forgejo/Gitea remote",
      "  3. Tea CLI configured (run: tea login add)",
    }, { title = "Forgejo PR Picker" })
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
    and Snacks.picker.config.defaults.forgejo_pr
  
  if has_registered then
    return Snacks.picker.forgejo_pr(opts)
  end
  
  -- Otherwise, call picker directly with our custom config
  local source = require("snacks.picker.source.forgejo")
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

---@class snacks.forgejo.CreatePROptions
---@field title? string PR title
---@field description? string PR description/body
---@field base? string Target branch (defaults to repo's default branch)
---@field head? string Source branch (defaults to current branch)

---@param opts? snacks.forgejo.CreatePROptions
function M.pr_create(opts)
  opts = opts or {}
  
  -- Ensure setup is called
  M.setup()
  
  -- Check if we're in a git repository
  local git_root = Snacks.git.get_root(vim.uv.cwd() or ".")
  if not git_root then
    Snacks.notify.error({
      "Not in a git repository",
      "",
      "Forgejo PR creation requires:",
      "  1. Being in a git repository",
      "  2. Having a Forgejo/Gitea remote",
      "  3. Tea CLI configured (run: tea login add)",
    }, { title = "Forgejo PR Create" })
    return
  end
  
  -- Check if tea is available (silent mode)
  if not M.health_check({ silent = true }) then
    return
  end
  
  -- Get git information
  local git = require("snacks.forgejo.git")
  local current_branch = git.get_current_branch()
  local default_branch = git.get_default_branch() or "main"
  
  if not current_branch then
    Snacks.notify.error("Could not determine current branch", { title = "Forgejo PR Create" })
    return
  end
  
  -- Create action context with branch info
  local actions = require("snacks.forgejo.actions")
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
function M.config()
  M._config = M._config or Snacks.config.get("forgejo", defaults)
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
      local ok, forgejo_source = pcall(require, "snacks.picker.source.forgejo")
      if ok then
        -- Register formatters
        Snacks.picker.format = Snacks.picker.format or {}
        Snacks.picker.format.forgejo_format = forgejo_source.format
        Snacks.picker.format.forgejo_actions_format = forgejo_source.actions_format
        
        -- Register preview
        Snacks.picker.preview = Snacks.picker.preview or {}
        Snacks.picker.preview.forgejo_preview = forgejo_source.preview
        
        -- Register finders
        Snacks.picker.finder = Snacks.picker.finder or {}
        Snacks.picker.finder.forgejo_pr = forgejo_source.pr
        Snacks.picker.finder.forgejo_actions = forgejo_source.actions
        
        -- Register actions
        local actions_ok, actions_mod = pcall(require, "snacks.forgejo.actions")
        if actions_ok and actions_mod.actions then
          for action_name, _ in pairs(actions_mod.actions) do
            if forgejo_source.actions[action_name] then
              Snacks.picker.actions[action_name] = forgejo_source.actions[action_name]
            end
          end
        end
        
        -- Register picker configuration
        local config_ok, forgejo_config = pcall(require, "snacks.picker.config.forgejo")
        if config_ok then
          for name, config in pairs(forgejo_config) do
            Snacks.picker.config.defaults[name] = config
          end
        end
      end
    end)
  end

  require("snacks.forgejo.buf").setup()
  if ev then
    vim.schedule(function()
      require("snacks.forgejo.buf").attach(ev.buf)
    end)
  end
  
  -- Create user commands
  vim.api.nvim_create_user_command("ForgejoPR", function(opts)
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
    desc = "List Forgejo Pull Requests",
  })
  
  vim.api.nvim_create_user_command("ForgejoPRCreate", function(opts)
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
    desc = "Create a Forgejo Pull Request",
  })
  
  vim.api.nvim_create_user_command("ForgejoHealth", function()
    M.health_check({ verbose = true })
  end, {
    nargs = 0,
    desc = "Check Forgejo/Tea CLI health",
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
    Snacks.notify.error(msg, { title = "Forgejo Health Check" })
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
      Snacks.notify.info(msg, { title = "Forgejo Health Check" })
      vim.print(table.concat(msg, "\n"))
    end
  else
    local msg = {
      ("✗ Tea CLI found but failed to execute: %s"):format(tea_cmd),
      ("Error: %s"):format(version_clean),
      "Check your installation",
    }
    Snacks.notify.warn(msg, { title = "Forgejo Health Check" })
    if opts.verbose then
      vim.print(table.concat(msg, "\n"))
    end
    return false
  end

  return true
end

return M
