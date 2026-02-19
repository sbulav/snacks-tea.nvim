---@meta

---@class snacks.tea.Config
---@field enabled? boolean
---@field tea? snacks.tea.tea.Config
---@field keys? table<string, snacks.tea.Keymap|false>
---@field wo? vim.wo|{}
---@field bo? vim.bo|{}
---@field diff? { min?: number, wrap?: number }
---@field scratch? { height?: number }
---@field icons? snacks.tea.icons

---@class snacks.tea.tea.Config
---@field cmd? string Path to tea binary (default: "tea")
---@field login? string Specific login to use, or nil for auto-detect
---@field remote? string Git remote to use (default: "origin")
---@field timeout? number Timeout for tea CLI commands in ms (default: 30000)

---@alias snacks.tea.Keymap.fn fun(item:snacks.picker.tea.Item, buf:snacks.tea.Buf)

---@class snacks.tea.Keymap: vim.keymap.set.Opts
---@field [1] string lhs
---@field [2] string|snacks.tea.Keymap.fn rhs
---@field mode? string|string[] defaults to `n`

---@class snacks.tea.icons
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

---@class snacks.tea.PR
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
---@field labels? snacks.tea.Label[]
---@field comments? snacks.tea.Comment[]
---@field diff? string
---@field patch? string

---@class snacks.tea.Label
---@field name string
---@field color string
---@field description? string

---@class snacks.tea.Comment
---@field id number
---@field body string
---@field user string
---@field created_at string
---@field updated_at? string

---@class snacks.picker.tea.Item: snacks.tea.PR
---@field uri string
---@field repo string
---@field type "pr"
---@field status? string
---@field dirty? boolean

---@class snacks.tea.Buf
---@field buf number
---@field opts snacks.tea.Config
---@field item snacks.tea.api.View

---@class snacks.tea.Meta
---@field desc string
---@field needs_setup boolean
---@field version string

---@class snacks.tea.api.View
---@field type "pr"
---@field repo string
---@field number number
---@field uri? string

---@class snacks.tea.api.Cmd
---@field args string[]
---@field repo? string
---@field input? string
---@field notify? boolean
---@field timeout? number Timeout in milliseconds
---@field on_error? fun(proc: snacks.spawn.Proc, err: string)

---@class snacks.tea.api.Fetch
---@field args string[]
---@field fields? string[]
---@field repo? string
---@field notify? boolean

---@class snacks.tea.action.ctx
---@field items snacks.picker.tea.Item[]
---@field picker? snacks.Picker
---@field main? number
---@field action? snacks.picker.Action

---@class snacks.tea.cli.Action.ctx
---@field item snacks.picker.tea.Item
---@field args string[]
---@field opts snacks.tea.cli.Action
---@field picker? snacks.Picker
---@field scratch? snacks.win
---@field main? number
---@field input? string

---@alias snacks.tea.action.fn fun(item?: snacks.picker.tea.Item, ctx: snacks.tea.action.ctx)

---@class snacks.tea.Action
---@field action snacks.tea.action.fn
---@field desc? string
---@field name? string
---@field priority? number
---@field title? string
---@field type? "pr"
---@field enabled? fun(item: snacks.picker.tea.Item, ctx: snacks.tea.action.ctx): boolean

---@class snacks.tea.cli.Action
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
---@field on_submit? fun(body: string, ctx: snacks.tea.cli.Action.ctx): string?
---@field enabled? fun(item: snacks.picker.tea.Item): boolean
---@field refresh? boolean

return {}
