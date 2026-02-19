# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-02-19

### Added

- Config validation with helpful error messages for invalid settings
- Configurable timeout for tea CLI commands (default: 30s, configurable via `tea.timeout`)
- Timeout error messages with guidance on increasing timeout

### Changed

- Extract GitHub remote detection to `Git.is_github_remote()` utility function
- Centralize git root detection in `Git.get_root()` wrapper

### Fixed

- Incorrect type check in `render/init.lua` `safe_field` function

## [0.1.0] - 2025-02-19

### Added

- Initial release of snacks-tea.nvim
- PR listing with filtering by state (open/closed/all)
- PR creation from current branch with scratch buffer editor
- PR actions: checkout, approve, reject, review, comment, merge, close, reopen
- Diff viewer with file-by-file navigation
- tea:// protocol buffers for PR viewing with markdown rendering
- Collapsible sections for comments and diffs
- UI customization with configurable highlights
- Layout configuration for different picker types
- Buffer commands: `:TeaRefresh`, `:TeaToggleComments`, `:TeaToggleDiff`
- User commands: `:TeaPR`, `:TeaPRCreate`, `:TeaHealth`
- Integration with render-markdown.nvim for enhanced rendering
- Configurable keymaps for PR actions
- Test suite using plenary.nvim

### Changed

### Deprecated

### Removed

### Fixed

### Security

## Versioning Policy

- **MAJOR** version for incompatible API changes
- **MINOR** version for new features (backwards compatible)
- **PATCH** version for bug fixes (backwards compatible)

[0.2.0]: https://github.com/sbulav/snacks-tea.nvim/releases/tag/v0.2.0
[0.1.0]: https://github.com/sbulav/snacks-tea.nvim/releases/tag/v0.1.0
