local Module = {}

function Module.setup(options)
	options = options or {}
	local keymap = options.keymap or '<C-_>'

	vim.keymap.set({'n', 'i', 'v'}, keymap, function()
		-- Supply the adding of comments
		local cmt = '//'
		local blockStart = '/*'
		local blockEnd = '*/'
		local isBlockComment = false
		local ft = vim.bo.filetype

		if ft == 'lua' then
			cmt = '--'
			blockStart = '--[' .. '['
			blockEnd = ']]'
		elseif ft == 'python' then
			cmt = '#'
		elseif ft == 'html' then
			blockStart = '<--'
			blockEnd = '-->'
			isBlockComment = true
		end

		local startRow = vim.fn.line("v") - 1
		local stopRow = vim.fn.line('.') - 1
		if stopRow < startRow then
			startRow, stopRow = stopRow, startRow
		end

		if stopRow - startRow > 0 and (cmt == '//' or cmt == '--') then
			isBlockComment = true
		end


		local firstLine = vim.api.nvim_buf_get_lines(0, startRow, startRow + 1, false)[1]

		-- Add comment if any of the selection contains a comment
		-- Otherwise, remove the comment
		local addComment = false
		for line = startRow, stopRow do
			local currentLine = vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1]
			if string.find(currentLine, cmt, nil, true) == nil and #currentLine >= #cmt then
				addComment = true
				break
			end
		end

		-- if addComment and isBlockComment then
			-- local firstLine = vim.api.nvim_buf_get_lines(0, startRow, startRow + 1, false)[1]
			-- vim.api.nvim_buf_set_lines(0, startRow, startRow + 1, false, { blockStart .. ' ' .. firstLine })
			-- local lastLine = vim.api.nvim_buf_get_lines(0, stopRow, stopRow + 1, false)[1]
			-- vim.api.nvim_buf_set_lines(0, stopRow, stopRow + 1, false, { lastLine .. ' ' .. blockEnd })
		-- end

		for line = startRow, stopRow do
			local currentLine = vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1]
			local indent = #string.match(currentLine, "%s*") + 1
			if addComment and string.sub(currentLine, indent, indent + #cmt - 1) ~= cmt and #currentLine > 0 then
				-- The below line makes comment string have the same indent as the text instead of being left-justified
				local subbed = string.sub(currentLine, 1, indent - 1) .. cmt .. ' ' .. string.sub(currentLine, indent + #cmt - 2)
				vim.api.nvim_buf_set_lines(0, line, line + 1, false, { subbed })
			elseif not addComment and string.sub(currentLine, indent, indent + #cmt - 1) == cmt then
				local subbed = string.sub(currentLine, 1, indent - 1) .. string.sub(currentLine, indent + #cmt + 1)
				vim.api.nvim_buf_set_lines(0, line, line + 1, false, { subbed })
			end
		end
		-- For exiting visual mode
		vim.api.nvim_feedkeys(vim.keycode'<Esc>', 'n', false)
	end)

end

return Module
