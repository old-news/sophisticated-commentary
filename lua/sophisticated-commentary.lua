local Module = {}

function Module.getIndent(line)
	-- This only matches comments at the start of a line, or immediately following whitespace.
	-- Therefore, inline comments will only be recognized if they begin the line.
	-- This preserves comments that come after some code on the same line.
	return #string.match(line, "%s*") + 1
end

function Module.addComment(line, comment, blockEnd)
	local addEnd = blockEnd or false
	if Module.lineHasComment(line, comment, addEnd) then
		return line
	end

	if addEnd then
		return line .. ' ' .. comment
	end

	local indent = Module.getIndent(line)
	-- The below line makes comment string have the same indent as the text instead of being left-justified
	local subbed = string.sub(line, 1, indent - 1) .. comment .. ' ' .. string.sub(line, indent + #comment - 2)
	return subbed
end

function Module.removeComment(line, comment, blockEnd)
	local removeEnd = blockEnd or false
	if not Module.lineHasComment(line, comment, blockEnd) then
		return line
	end

	if removeEnd then
		return string.sub(line, 1, #line - #comment)
	end

	local indent = Module.getIndent(line)
	local subbed = string.sub(line, 1, indent - 1) .. string.sub(line, indent + #comment + 1)
	return subbed
end

function Module.lineHasComment(line, comment, blockEnd)
	local checkEnd = blockEnd or false
	if checkEnd then
		-- For checking blockEnds of block comments
		return string.sub(line, #line - #comment) ~= nil
	end

	local indent = Module.getIndent(line)
	local removedIndent = string.sub(line, indent)
	return string.sub(removedIndent, 1, #comment) == comment
end

function Module.getLine(number)
	return vim.api.nvim_buf_get_lines(0, number, number + 1, false)[1]
end

function Module.putLine(number, text)
	vim.api.nvim_buf_set_lines(0, number, number + 1, false, { text })
end

function Module.getCommentStyle(filetype)
	-- blockstatus:
	-- 	0 - Language does not support block comments (python)
	-- 	1 - Language does support block comments (c, c++, css, javascript, ...)
	-- 	2 - The only type of comment for the language is block. No inline comments allowed! (html)
	local cmt = '//'
	local blockStart = ''
	local blockEnd = ''
	local blockStatus = 0
	if 'lua' == filetype then
		cmt = '--'
		blockStart = '--[' .. '['
		blockEnd = ']]'
		blockStatus = 1
	elseif 'python' == filetype then
		cmt = '#'
		blockStatus = 0
	elseif 'html' == filetype then
		blockStart = '<--'
		blockEnd = '-->'
		blockStatus = 2
	end
	return cmt, blockStart, blockEnd, blockStatus
end

function Module.setup(opts)
	opts = opts or {}
	local keymap = opts.keymap or '<C-_>'

	vim.keymap.set({'n', 'i', 'v'}, keymap, function()
		-- Supply the adding of comments
		local isMultilineComment = false
		local cmt, blockStart, blockEnd, blockStatus = Module.getCommentStyle(vim.bo.filetype)

		local startRow = vim.fn.line("v") - 1
		local stopRow = vim.fn.line('.') - 1
		if stopRow < startRow then
			startRow, stopRow = stopRow, startRow
		end

		if stopRow - startRow > 0 and (cmt == '//' or cmt == '--') then
			isMultilineComment = true
		end

		-- Add comment if any of the selection contains a comment
		-- Otherwise, remove the comment
		local addComment = false
		for line = startRow, stopRow do
			local currentLine = Module.getLine(line)
			if not Module.lineHasComment(line, cmt, false) and #currentLine >= #cmt then
				addComment = true
				break
			end
		end

		for line = startRow, stopRow do
			if addComment then
				Module.addComment(line, cmt, false)
			else
				Module.removeComment(line, cmt, false)
			end
		end
		-- For exiting visual mode
		vim.api.nvim_feedkeys(vim.keycode'<Esc>', 'n', false)
	end)

end

return Module
