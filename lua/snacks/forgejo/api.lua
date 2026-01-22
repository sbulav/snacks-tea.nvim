local Async = require("snacks.picker.util.async")
local Item = require("snacks.forgejo.item")
local Proc = require("snacks.util.spawn")

---@class snacks.forgejo.api
local M = {}

---@type table<string, snacks.picker.forgejo.Item>
local cache = setmetatable({}, { __mode = "v" })
local pr_cache = {} ---@type table<string, snacks.picker.forgejo.Item>

---@type table<string, snacks.forgejo.api.Config|{}>
local config = {
  base = {
    list = {
      "index",
      "title",
      "state",
      "author",
      "author-id",
      "url",
      "body",
      "base",
      "base-commit",
      "head",
      "created",
      "updated",
      "deadline",
      "assignees",
      "milestone",
      "labels",
    },
    view = { "comments", "mergeable", "head", "diff", "patch" },
    text = { "author", "title" },
    options = { "state", "limit", "repo", "remote", "login", "output" },
  },
  pr = {
    ---@param item snacks.picker.forgejo.Item
    transform = function(item)
      item.status = item.state
      return item
    end,
  },
}

---@param item snacks.forgejo.api.View
local function cache_get(item)
  return cache[Item.to_uri(item)]
end

---@param item snacks.picker.forgejo.Item
local function cache_set(item)
  cache[item.uri] = item
  return item
end

---@generic T
---@param fn fun(cb:fun(proc:snacks.spawn.Proc, data?:any), opts:T): snacks.spawn.Proc
---@return fun(opts:T): any?
local function wrap_sync(fn)
  ---@async
  return function(opts)
    local ret ---@type any
    fn(function(_, data)
      ret = data
    end, opts):wait()
    return ret
  end
end

---@param what "pr"
---@param key "list" | "view"
local function get_opts(what, key)
  local base = vim.deepcopy(config.base)
  local specific = vim.deepcopy(config[what] or {})
  base.type = what
  base.fields = vim.deepcopy(base.list or {})
  if key ~= "list" then
    base.fields = vim.list_extend(base.fields, base[key] or {})
    base.fields = vim.list_extend(base.fields, specific[key] or {})
  end
  base.text = vim.list_extend(base.text, specific.text or {})
  base.options = vim.list_extend(base.options, specific.options or {})
  base.transform = specific.transform
  return base
end

---@param args string[]
---@param options string[]
---@param opts table<string, string|boolean|number|nil>
local function set_options(args, options, opts)
  for _, option in ipairs(options or {}) do
    local value = opts[option] ---@type string|boolean|number|nil
    if type(value) == "boolean" and value then
      args[#args + 1] = "--" .. option
    elseif value and value ~= "" then
      vim.list_extend(args, { "--" .. option, tostring(value) })
    end
  end
end

---@param cb fun(proc: snacks.spawn.Proc, data?: string)
---@param opts snacks.forgejo.api.Cmd
function M.cmd(cb, opts)
  opts = opts or {}
  local args = vim.deepcopy(opts.args)
  if opts.repo then
    vim.list_extend(args, { "--repo", opts.repo })
  end
  
  local config = require("snacks.forgejo").config()
  local tea_cmd = config.tea.cmd or "tea"
  
  if config.tea.remote then
    vim.list_extend(args, { "--remote", config.tea.remote })
  end
  if config.tea.login then
    vim.list_extend(args, { "--login", config.tea.login })
  end
  
  local Spawn = require("snacks.util.spawn")
  local async = Async.running()
  local ret ---@type snacks.spawn.Proc

  if async then
    async:on("abort", function()
      if ret and ret:running() then
        ret:kill()
      end
    end)
  end
  
  ret = Spawn.new({
    cmd = tea_cmd,
    args = args,
    input = opts.input,
    timeout = 10000,
    on_exit = function(proc, err)
      if err then
        vim.schedule(function()
          if not proc.aborted then
            if opts.notify ~= false then
              local stderr = proc:err() or ""
              local helpful_msg = {}
              
              -- Provide helpful error messages
              if stderr:match("not a gitea/forgejo repository") or stderr:match("No Gitea login") then
                helpful_msg = {
                  "This doesn't appear to be a Forgejo/Gitea repository",
                  "",
                  "Make sure you:",
                  "  1. Have a Forgejo or Gitea remote configured",
                  "  2. Have tea CLI configured: tea login add",
                  "  3. Are in the correct repository",
                }
              elseif stderr:match("could not open a new TTY") then
                -- This is just a warning, not a fatal error
                -- If there's output, the command likely succeeded
                if proc:out() and proc:out():match("%S") then
                  -- Has output, treat as success
                  return cb(proc, proc:out())
                end
                helpful_msg = {
                  "Tea CLI TTY warning (usually harmless)",
                  "",
                  "If this persists, check:",
                  "  1. Tea CLI is configured: tea login list",
                  "  2. Repository has Forgejo/Gitea remote",
                }
              else
                helpful_msg = { stderr }
              end
              
              Snacks.debug.cmd({
                header = "Tea CLI Error",
                cmd = { tea_cmd, unpack(args) },
                footer = table.concat(helpful_msg, "\n"),
                level = vim.log.levels.ERROR,
                props = { input = opts.input },
              })
            end
            if opts.on_error then
              opts.on_error(proc, proc:err())
            end
          end
        end)
        return
      end
      return cb(proc, not err and proc:out() or nil)
    end,
  })
  return ret
end
M.cmd_sync = wrap_sync(M.cmd)

---@param cb fun(proc: snacks.spawn.Proc, data?: unknown)
---@param opts snacks.forgejo.api.Fetch
function M.fetch(cb, opts)
  local args = vim.deepcopy(opts.args)
  
  -- Add output format and fields
  vim.list_extend(args, { "--output", "json" })
  if opts.fields and #opts.fields > 0 then
    vim.list_extend(args, { "--fields", table.concat(opts.fields, ",") })
  end
  
  return M.cmd(function(proc, data)
    if not data then
      return cb(proc, nil)
    end
    
    -- Try to parse JSON, with better error handling
    local ok, result = pcall(function()
      return proc:json()
    end)
    
    if not ok then
      -- JSON parsing failed, likely due to stderr contamination
      -- Try to extract JSON from the output
      local json_str = data:match("%[.+%]") or data:match("%{.+%}")
      if json_str then
        ok, result = pcall(vim.json.decode, json_str)
      end
      
      if not ok then
        -- Still failed, log the error but don't notify (it's cached on second try)
        if opts.notify ~= false then
          vim.schedule(function()
            Snacks.notify.warn({
              "Failed to parse tea CLI output as JSON",
              "Command: tea " .. table.concat(args, " "),
              "Output preview: " .. data:sub(1, 100),
            }, { title = "Forgejo API" })
          end)
        end
        return cb(proc, nil)
      end
    end
    
    cb(proc, result)
  end, {
    args = args,
    repo = opts.repo,
    notify = opts.notify,
  })
end
M.fetch_sync = wrap_sync(M.fetch)

---@param what "pr"
---@param cb fun(items?: snacks.picker.forgejo.Item[])
---@param opts? snacks.picker.forgejo.Config
function M.list(what, cb, opts)
  opts = opts or {}
  local api_opts = get_opts(what, "list")
  local args = { what, "ls" }

  vim.list_extend(args, { "--limit", tostring(opts.limit or 30) })
  set_options(args, api_opts.options, opts)

  ---@param data? snacks.forgejo.PR[]
  return M.fetch(function(_, data)
    if not data then
      return cb()
    end
    ---@param item snacks.forgejo.PR
    return cb(vim.tbl_map(function(item)
      return cache_set(Item.new(item, api_opts))
    end, data))
  end, {
    args = args,
    fields = api_opts.fields,
    repo = opts.repo,
  })
end

---@param cb fun(item?: snacks.picker.forgejo.Item, updated?: boolean)
---@param item snacks.forgejo.api.View|{number?: number}
---@param opts? { fields?: string[], force?: boolean }
function M.view(cb, item, opts)
  opts = opts or {}
  local api_opts = get_opts(item.type, "view")
  if opts.fields then
    api_opts.fields = vim.list_extend(api_opts.fields, opts.fields)
  end

  item = M.get_cached(item)
  
  -- If item is not an Item object, we need all fields
  local todo = api_opts.fields
  if Item.is(item) then
    todo = item:need(api_opts.fields)
    if opts.force or item.dirty then
      todo = api_opts.fields
    end
  end

  if #todo == 0 then
    cb(item, false)
    return
  end

  -- Tea CLI doesn't support viewing individual PRs with `tea pr <number>`
  -- We need to use `tea pr ls` and filter by the specific PR
  -- This is a limitation of the tea CLI
  local args = { item.type, "ls" }
  local it ---@type snacks.forgejo.PR?

  ---@param data? snacks.forgejo.PR|snacks.forgejo.PR[]|{}
  local function handler(data)
    -- tea pr ls returns an array, we need to find our specific PR
    -- Check if it's an array by looking for numeric keys
    local is_list = type(data) == "table" and data[1] ~= nil
    if is_list then
      -- Filter for the specific PR number
      local target_number = tonumber(item.number) or item.number
      for _, pr in ipairs(data) do
        if pr.index == target_number or tonumber(pr.index) == target_number then
          data = pr
          is_list = false
          break
        end
      end
      -- If we didn't find it, data will still be the array
      if is_list then
        -- PR not found in the list
        return cb(item, false)
      end
    end
    
    it = data and vim.tbl_extend("force", it or {}, data or {}) or it
    if not it then
      return cb(item, false)
    end
    
    -- If item is already an Item object, just update it
    -- Otherwise, create a new Item from the data
    if Item.is(item) then
      item:update(it, todo)
    else
      -- Merge the basic item info (repo, type, number) with fetched data
      local merged = vim.tbl_extend("force", it, {
        repo = item.repo,
        type = item.type,
        number = tonumber(item.number) or item.number,
      })
      item = Item.new(merged, api_opts)
    end
    
    item.dirty = false
    cb(cache_set(item), true)
  end

  ---@param data? snacks.forgejo.PR
  -- For tea pr ls, we need to add state=all and use limit to reduce overhead
  -- We'll filter for our specific PR in the handler
  vim.list_extend(args, { "--state", "all", "--limit", "100" })
  
  local proc = M.fetch(function(_, data)
    handler(data)
  end, {
    args = args,
    fields = todo,
    repo = item.repo or api_opts.repo,
  })

  ---@type snacks.picker.Waitable
  return {
    ---@async
    wait = function()
      proc:wait()
    end,
  }
end

---@param item snacks.forgejo.api.View
---@param opts? { fields?: string[], force?: boolean }
---@async
function M.get(item, opts)
  local ret ---@type snacks.picker.forgejo.Item?
  local procs = M.view(function(it)
    ret = it
  end, item, opts)
  if procs then
    procs:wait()
  end
  return ret
end

---@param item snacks.forgejo.api.View
function M.get_cached(item)
  return not Item.is(item) and cache_get(item) or item
end

---@param item snacks.picker.forgejo.Item
function M.refresh(item)
  item.dirty = true
  cache_set(item)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      if vim.api.nvim_buf_get_name(buf) == item.uri then
        require("snacks.forgejo.buf").attach(buf, item)
      end
    end
  end
end

---@async
function M.current_pr()
  local root = Snacks.git.get_root(vim.uv.cwd() or ".")
  if not root then
    return
  end
  ---@type snacks.picker.forgejo.Item?
  local pr
  local branch = Proc.exec({ "git", "branch", "--show-current" })

  local key = root .. "::" .. branch
  if pr_cache[key] then
    return pr_cache[key]
  end

  -- Try with `pr view` first
  local api_opts = get_opts("pr", "list")
  pr = M.fetch_sync({
    args = { "pr" },
    fields = api_opts.fields,
    notify = false,
  })
  pr = pr and cache_set(Item.new(pr, api_opts)) or nil
  if pr then
    pr_cache[key] = pr
    return pr
  end

  return nil
end

---@class snacks.forgejo.api.CreatePR
---@field title? string PR title
---@field description? string PR description/body
---@field base? string Target branch (defaults to repo's default branch)
---@field head? string Source branch (defaults to current branch)
---@field assignees? string Comma-separated list of usernames
---@field labels? string Comma-separated list of labels
---@field milestone? string Milestone to assign
---@field deadline? string Deadline timestamp
---@field repo? string Repository override

---@param cb fun(proc: snacks.spawn.Proc, pr_url?: string)
---@param opts snacks.forgejo.api.CreatePR
function M.create(cb, opts)
  opts = opts or {}
  local args = { "pr", "create" }
  
  -- Add title and description
  if opts.title then
    vim.list_extend(args, { "--title", opts.title })
  end
  if opts.description then
    vim.list_extend(args, { "--description", opts.description })
  end
  
  -- Add branch options
  if opts.base then
    vim.list_extend(args, { "--base", opts.base })
  end
  if opts.head then
    vim.list_extend(args, { "--head", opts.head })
  end
  
  -- Add optional metadata
  if opts.assignees then
    vim.list_extend(args, { "--assignees", opts.assignees })
  end
  if opts.labels then
    vim.list_extend(args, { "--labels", opts.labels })
  end
  if opts.milestone then
    vim.list_extend(args, { "--milestone", opts.milestone })
  end
  if opts.deadline then
    vim.list_extend(args, { "--deadline", opts.deadline })
  end
  
  -- Always enable maintainer edits
  vim.list_extend(args, { "--allow-maintainer-edits" })
  
  -- tea pr create doesn't support --output json, it just prints the URL
  return M.cmd(function(proc, data)
    if not data then
      return cb(proc, nil)
    end
    -- Extract PR URL from output (usually the last line)
    local url = data:match("(https?://[^\n]+)")
    cb(proc, url)
  end, {
    args = args,
    repo = opts.repo,
  })
end
M.create_sync = wrap_sync(M.create)

return M
