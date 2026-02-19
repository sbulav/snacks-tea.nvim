local Item = require("snacks.tea.item")
local eq = assert.are.same

describe("item module", function()
	describe("is", function()
		it("returns false for plain tables", function()
			assert.is_false(Item.is({}))
			assert.is_false(Item.is({ index = 1, title = "test" }))
		end)

		it("returns true for Item instances", function()
			local item = Item.new({
				index = 1,
				title = "Test PR",
				state = "open",
				author = "user",
				url = "https://example.com/owner/repo/pulls/1",
			}, {})
			assert.is_true(Item.is(item))
		end)
	end)

	describe("get_repo", function()
		it("extracts owner/repo from URL", function()
			local repo = Item.get_repo("https://gitea.example.com/owner/repo/pulls/123")
			eq("owner/repo", repo)
		end)

		it("extracts from different URL formats", function()
			local repo = Item.get_repo("https://codeberg.org/user/project/pulls/456")
			eq("user/project", repo)
		end)

		it("returns empty string for invalid URLs", function()
			eq("", Item.get_repo("not-a-url"))
			eq("", Item.get_repo(""))
		end)
	end)

	describe("to_uri", function()
		it("creates tea:// URI", function()
			local uri = Item.to_uri({ repo = "owner/repo", type = "pr", number = 123 })
			eq("tea://owner/repo/pr/123", uri)
		end)
	end)

	describe("new", function()
		it("creates Item with required fields", function()
			local item = Item.new({
				index = 42,
				title = "Fix bug",
				state = "open",
				author = "developer",
				url = "https://example.com/owner/repo/pulls/42",
			}, {})

			eq(42, item.index)
			eq(42, item.number)
			eq("Fix bug", item.title)
			eq("open", item.state)
			eq("developer", item.author)
			eq("pr", item.type)
			eq("owner/repo", item.repo)
			eq("tea://owner/repo/pr/42", item.uri)
		end)

		it("converts hyphenated field names", function()
			local item = Item.new({
				index = 1,
				title = "Test",
				state = "open",
				author = "user",
				url = "https://example.com/owner/repo/pulls/1",
				["base-commit"] = "abc123",
			}, {})

			eq("abc123", item.base_commit)
		end)

		it("extracts repo from URL if not provided", function()
			local item = Item.new({
				index = 1,
				title = "Test",
				state = "open",
				author = "user",
				url = "https://forgejo.test/myorg/myrepo/pulls/1",
			}, {})

			eq("myorg/myrepo", item.repo)
		end)
	end)

	describe("need", function()
		it("returns missing fields", function()
			local item = Item.new({
				index = 1,
				title = "Test",
				state = "open",
				author = "user",
				url = "https://example.com/owner/repo/pulls/1",
			}, {})

			local needed = item:need({ "body", "comments", "title" })
			eq({ "body", "comments" }, needed)
		end)

		it("returns empty table if all fields present", function()
			local item = Item.new({
				index = 1,
				title = "Test",
				state = "open",
				author = "user",
				url = "https://example.com/owner/repo/pulls/1",
				body = "Description",
			}, {})

			local needed = item:need({ "title", "body", "state" })
			eq({}, needed)
		end)
	end)

	describe("update", function()
		it("updates fields from data", function()
			local item = Item.new({
				index = 1,
				title = "Old title",
				state = "open",
				author = "user",
				url = "https://example.com/owner/repo/pulls/1",
			}, {})

			item:update({ title = "New title", state = "closed" }, { "title", "state" })

			eq("New title", item.title)
			eq("closed", item.state)
		end)

		it("handles hyphenated field names from tea CLI", function()
			local item = Item.new({
				index = 1,
				title = "Test",
				state = "open",
				author = "user",
				url = "https://example.com/owner/repo/pulls/1",
			}, {})

			item:update({ ["base-commit"] = "def456" }, { "base_commit" })

			eq("def456", item.base_commit)
		end)
	end)
end)
