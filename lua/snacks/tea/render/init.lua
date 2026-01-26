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
      local hl = "SnacksTeaPr" .. U.title(status)
      local text = icon .. U.title(status)
      H.extend(ret, H.badge(text, { bg = Snacks.util.color(hl), fg = "#ffffff" }))
      if safe_field(item, "base") ~= "" and safe_field(item, "head") ~= "" then
        ret[#ret + 1] = { " " }
        vim.list_extend(ret, {
          { safe_field(item, "base"), "SnacksTeaBranch" },
          { " ← ", "SnacksTeaDelim" },
          { safe_field(item, "head"), "SnacksTeaBranch" },
        })
      end
      return ret
    end,
  },
  {
    name = "Author",
    hl = function(item, opts)
      local author = safe_field(item, "author", "Unknown")
      return H.badge(opts.icons.user .. " " .. author, "SnacksTeaUserBadge")
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
  H.extend(ret, H.badge(opts.icons.user .. " " .. user, "SnacksTeaUserBadge"))
  local created = safe_field(comment, "created", "Unknown")
  ret[#ret + 1] = { " · " .. created, "SnacksPickerGitDate" }
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

  -- Header with state
  local state_icon = opts.icons.pr[safe_field(item, "state", "other"):lower()] or opts.icons.pr.other or " "
  local state_hl = "SnacksTeaPr" .. U.title(safe_field(item, "state", "other"))
  local header = { { "# " }, { state_icon, state_hl }, { " PR #" .. safe_field(item, "number", "?") .. ": " }, { safe_field(item, "title", "Untitled") } }
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

  -- Comments
  local threads = safe_field(item, "comments", {})
  if type(threads) ~= "table" then threads = {} end
  if #threads > 0 then
    lines[#lines + 1] = { { "## 💬 Comments" } }
    lines[#lines + 1] = {}
    for _, comment in ipairs(threads) do
      local header = M.comment_header(comment, opts)
      lines[#lines + 1] = header
      local body_lines = M.comment_body(comment)
      body_lines = indent(body_lines, { markdown = true })
      vim.list_extend(lines, body_lines)
      lines[#lines + 1] = {}
    end
  end

  -- Diff
  if safe_field(item, "diff", "") ~= "" and not opts.partial then
    lines[#lines + 1] = { { "---" } }
    lines[#lines + 1] = {}
    lines[#lines + 1] = { { "## Diff" } }
    lines[#lines + 1] = {}
    lines[#lines + 1] = { { "```diff" } }
    local diff_lines = vim.split(safe_field(item, "diff", ""), "\n")
    for _, dl in ipairs(diff_lines) do
      local prefix = dl:match("^([ +%-])")
      local hl_group = prefix == "+" and "DiffAdd" or prefix == "-" and "DiffDelete" or "DiffText"
      lines[#lines + 1] = { { dl, hl_group } }
    end
    lines[#lines + 1] = { { "```" } }
    lines[#lines + 1] = {}
  end

  local changed = H.render(buf, ns, lines)

  if changed then
    Markdown.render(buf, { bullets = false })
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