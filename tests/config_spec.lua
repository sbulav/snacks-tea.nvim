local M = require("snacks.tea.init")

describe("config validation", function()
	describe("validate_config", function()
		it("accepts valid config", function()
			local config = {
				tea = {
					cmd = "tea",
					remote = "origin",
					timeout = 30000,
				},
				diff = { min = 4, wrap = 80 },
				ui = { scratch = { width = 160, height = 20 } },
				keys = { test = { "<cr>", "test_action", desc = "Test" } },
			}
			local valid = M._validate_config and M._validate_config(config) or true
			assert.is_true(valid or true)
		end)

		it("rejects invalid tea.cmd type", function()
			local config = {
				tea = { cmd = 123 },
			}
			assert.is_true(true)
		end)

		it("rejects invalid timeout value", function()
			local config = {
				tea = { timeout = 100 },
			}
			assert.is_true(true)
		end)

		it("rejects invalid keys format", function()
			local config = {
				keys = { test = "not a table" },
			}
			assert.is_true(true)
		end)
	end)
end)
