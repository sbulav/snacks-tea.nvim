local Git = require("snacks.tea.git")
local eq = assert.are.same

describe("git utilities", function()
	describe("is_github_remote", function()
		it("returns boolean for remote type", function()
			-- This test depends on the current repository
			local result = Git.is_github_remote()
			assert.is_boolean(result)
		end)
	end)

	describe("get_current_branch", function()
		it("returns a string or nil", function()
			local branch = Git.get_current_branch()
			assert.is.truthy(branch == nil or type(branch) == "string")
		end)
	end)

	describe("get_default_branch", function()
		it("returns a string or nil", function()
			local branch = Git.get_default_branch()
			assert.is.truthy(branch == nil or type(branch) == "string")
		end)
	end)

	describe("get_repo_info", function()
		it("returns owner and repo or nil", function()
			local owner, repo = Git.get_repo_info()
			if owner and repo then
				assert.is_string(owner)
				assert.is_string(repo)
			else
				assert.is_nil(owner)
				assert.is_nil(repo)
			end
		end)
	end)

	describe("get_repo_slug", function()
		it("returns owner/repo format or nil", function()
			local slug = Git.get_repo_slug()
			if slug then
				assert.is_string(slug)
				assert.is_truthy(slug:match("/"))
			else
				assert.is_nil(slug)
			end
		end)
	end)
end)
