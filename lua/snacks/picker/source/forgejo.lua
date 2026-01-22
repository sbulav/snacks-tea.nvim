local Actions = require("snacks.forgejo.actions")
local Api = require("snacks.forgejo.api")

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
        if item.forgejo_item then
          item = item.forgejo_item
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

---@param opts snacks.picker.forgejo.Config
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
  local config = require("snacks.forgejo").config()
  local ret = {} ---@type snacks.picker.Highlight[]
  local icons = config.icons

  -- State icon
  local state_icon = icons.pr[item.state] or icons.pr.other
  local state_hl = "SnacksForgejoPr" .. item.state:sub(1, 1):upper() .. item.state:sub(2)
  ret[#ret + 1] = { state_icon .. " ", state_hl }

  -- PR number
  ret[#ret + 1] = { "#" .. item.number .. " ", "SnacksForgejoNumber" }

  -- Title
  ret[#ret + 1] = { item.title or "", "Normal" }

  -- Author
  if item.author then
    ret[#ret + 1] = { " " }
    ret[#ret + 1] = { icons.user, "SnacksForgejoGray" }
    ret[#ret + 1] = { item.author, "SnacksForgejoGray" }
  end

  -- Labels
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
  local config = require("snacks.forgejo").config()
  local item = ctx.item
  
  -- Store the forgejo item for actions
  ctx.item.forgejo_item = item
  
  -- Set window and buffer options for preview
  item.wo = config.wo
  item.bo = config.bo
  
  -- Set preview title
  item.preview_title = ("%s PR #%s"):format(
    config.icons.logo,
    (item.number or item.index or "")
  )
  
  -- Make sure the item has a file field pointing to the URI
  if not item.file and item.uri then
    item.file = item.uri
  end
  
  return Snacks.picker.preview.file(ctx)
end

return M
