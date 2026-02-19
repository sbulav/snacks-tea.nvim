#!/usr/bin/env nvim -l

-- Minimal test runner for snacks-tea.nvim
-- Usage: nvim -l scripts/test.lua [pattern]

-- Add plugin to runtime path
vim.opt.rtp:prepend(vim.fn.getcwd())

-- Check for plenary
local ok, plenary = pcall(require, "plenary")
if not ok then
	print("Error: plenary.nvim is required for testing")
	print("Install with: luarocks install plenary.nvim")
	os.exit(1)
end

-- Run tests
local test_pattern = arg[1] or "tests/*_spec.lua"

require("plenary.test_harness").test_directory(test_pattern, {
	minimal = false,
	sequential = true,
})
