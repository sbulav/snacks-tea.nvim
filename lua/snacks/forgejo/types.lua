---@meta

---@class snacks.forgejo.Config
---@field enabled? boolean
---@field tea? snacks.forgejo.tea.Config
---@field keys? table<string, snacks.forgejo.Keymap|false>
---@field wo? vim.wo|{}
---@field bo? vim.bo|{}
---@field diff? { min?: number, wrap?: number }
---@field scratch? { height?: number }
---@field icons? snacks.forgejo.icons

---@class snacks.forgejo.tea.Config
---@field cmd? string Path to tea binary (default: "tea")
---@field login? string Specific login to use, or nil for auto-detect
---@field remote? string Git remote to use (default: "origin")

---@alias snacks.forgejo.Keymap.fn fun(item:snacks.picker.forgejo.Item, buf:snacks.forgejo.Buf)

---@class snacks.forgejo.Keymap: vim.keymap.set.Opts
---@field [1] string lhs
---@field [2] string|snacks.forgejo.Keymap.fn rhs
---@field mode? string|string[] defaults to `n`

---@class snacks.forgejo.icons
---@field logo? string
---@field user? string
---@field checkmark? string
---@field crossmark? string
---@field block? string
---@field file? string
---@field checks? { pending?: string, success?: string, failure?: string, skipped?: string }
---@field pr? { open?: string, closed?: string, merged?: string, draft?: string, other?: string }
---@field review? { approved?: string, changes_requested?: string, commented?: string, dismissed?: string, pending?: string }
---@field merge_status? { clean?: string, dirty?: string, blocked?: string, unstable?: string }

---@class snacks.forgejo.PR
---@field index number
---@field title string
---@field state "open"|"closed"
---@field author string
---@field author_id number
---@field url string
---@field body? string
---@field base string Base branch
---@field base_commit? string
---@field head string Head branch
---@field head_commit? string
---@field mergeable? boolean
---@field created_at? string
---@field updated_at? string
---@field deadline? string
---@field assignees? string[]
---@field milestone? string
---@field labels? snacks.forgejo.Label[]
---@field comments? snacks.forgejo.Comment[]
---@field diff? string
---@field patch? string

---@class snacks.forgejo.Label
---@field name string
---@field color string
---@field description? string

---@class snacks.forgejo.Comment
---@field id number
---@field body string
---@field user string
---@field created_at string
---@field updated_at? string

---@class snacks.picker.forgejo.Item: snacks.forgejo.PR
---@field uri string
---@field repo string
---@field type "pr"
---@field number number
---@field status? string
---@field dirty? boolean

---@class snacks.forgejo.api.View
---@field type "pr"
---@field repo string
---@field number number
---@field uri? string

---@class snacks.forgejo.api.Cmd
---@field args string[]
---@field repo? string
---@field input? string
---@field notify? boolean
---@field on_error? fun(proc: snacks.spawn.Proc, err: string)

---@class snacks.forgejo.api.Fetch
---@field args string[]
---@field fields? string[]
---@field repo? string
---@field notify? boolean

---@class snacks.forgejo.action.ctx
---@field items snacks.picker.forgejo.Item[]
---@field picker? snacks.Picker
---@field main? number
---@field action? snacks.picker.Action

---@class snacks.forgejo.cli.Action.ctx
---@field item snacks.picker.forgejo.Item
---@field args string[]
---@field opts snacks.forgejo.cli.Action
---@field picker? snacks.Picker
---@field scratch? snacks.win
---@field main? number
---@field input? string

---@alias snacks.forgejo.action.fn fun(item?: snacks.picker.forgejo.Item, ctx: snacks.forgejo.action.ctx)

---@class snacks.forgejo.Action
---@field action snacks.forgejo.action.fn
---@field desc? string
---@field name? string
---@field priority? number
---@field title? string
---@field type? "pr"
---@field enabled? fun(item: snacks.picker.forgejo.Item, ctx: snacks.forgejo.action.ctx): boolean

---@class snacks.forgejo.cli.Action
---@field cmd? string
---@field icon? string
---@field title? string
---@field success? string
---@field desc? string
---@field type? "pr"
---@field args? string[]
---@field confirm? string
---@field edit? string
---@field template? string
---@field on_submit? fun(body: string, ctx: snacks.forgejo.cli.Action.ctx): string?
---@field enabled? fun(item: snacks.picker.forgejo.Item): boolean
---@field refresh? boolean

return {}
