local M = {}

--- Get current git branch name
---@return string? branch Current branch name or nil if not in a git repo
function M.get_current_branch()
	local branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
	if vim.v.shell_error == 0 and branch ~= "" then
		return branch
	end
	return nil
end

--- Get default branch of remote repository
---@param remote? string Remote name (default: "origin")
---@return string? branch Default branch name or nil
function M.get_default_branch(remote)
	remote = remote or "origin"

	-- Method 1: Try git symbolic-ref (works if remote HEAD is set)
	local cmd = string.format("git symbolic-ref refs/remotes/%s/HEAD 2>/dev/null", remote)
	local ref = vim.fn.system(cmd):gsub("\n", "")
	if vim.v.shell_error == 0 and ref ~= "" then
		-- Extract branch name from refs/remotes/origin/main
		local branch = ref:match("^refs/remotes/" .. remote .. "/(.+)$")
		if branch then
			return branch
		end
	end

	-- Method 2: Try git remote show (slower but more reliable)
	cmd = string.format("git remote show %s 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5", remote)
	local branch = vim.fn.system(cmd):gsub("\n", "")
	if vim.v.shell_error == 0 and branch ~= "" then
		return branch
	end

	-- Method 3: Try common defaults
	for _, default in ipairs({ "main", "master", "develop" }) do
		cmd = string.format("git rev-parse --verify refs/remotes/%s/%s 2>/dev/null", remote, default)
		if vim.fn.system(cmd) ~= "" and vim.v.shell_error == 0 then
			return default
		end
	end

	return nil
end

--- Get repository owner and name from git remote
---@param remote? string Remote name (default: "origin")
---@return string? owner Repository owner
---@return string? repo Repository name
function M.get_repo_info(remote)
	remote = remote or "origin"
	local cmd = string.format("git remote get-url %s 2>/dev/null", remote)
	local url = vim.fn.system(cmd):gsub("\n", "")

	if vim.v.shell_error ~= 0 or url == "" then
		return nil, nil
	end

	-- Parse SSH URL: git@host:owner/repo.git
	local owner, repo = url:match("git@[^:]+:([^/]+)/(.+)%.git$")
	if owner and repo then
		return owner, repo
	end

	-- Parse HTTPS URL: https://host/owner/repo.git
	owner, repo = url:match("https?://[^/]+/([^/]+)/(.+)%.git$")
	if owner and repo then
		return owner, repo
	end

	-- Parse without .git extension
	owner, repo = url:match("git@[^:]+:([^/]+)/(.+)$")
	if owner and repo then
		return owner, repo
	end

	owner, repo = url:match("https?://[^/]+/([^/]+)/(.+)$")
	if owner and repo then
		return owner, repo
	end

	return nil, nil
end

--- Get full repository slug (owner/repo)
---@param remote? string Remote name (default: "origin")
---@return string? slug Repository slug in "owner/repo" format
function M.get_repo_slug(remote)
	local owner, repo = M.get_repo_info(remote)
	if owner and repo then
		return owner .. "/" .. repo
	end
	return nil
end

return M
