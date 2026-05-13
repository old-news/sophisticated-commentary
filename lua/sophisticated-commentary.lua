local Module = {}

function Module.getIndent(line)
	-- This only matches comments at the start of a line, or immediately following whitespace.
	-- Therefore, inline comments will only be recognized if they begin the line.
	-- This preserves comments that come after some code on the same line.
	return #string.match(line, "%s*") + 1
	-- return #line:match('%s*') + 1
end

function Module.getIndentString(line, indent)
	return string.sub(line, 1, indent - 1)
end

function Module.lineIsWSpace(line)
	return 0 == #string.gsub(line, '%s*', '')
end

function Module.addComment(line, comment, lookatEnd, commentMatchesIndentation)
	lookatEnd = lookatEnd or false
	local matchIndent = commentMatchesIndentation and true
	if Module.lineHasComment(line, comment, lookatEnd) or Module.lineIsWSpace(line) then
		return line
	end

	if lookatEnd then
		return line .. ' ' .. comment
	end

	local indent = Module.getIndent(line)
	-- The below line makes comment string have the same indent as the text instead of being left-justified
	local subbed = string.gsub(line, "^%s*" .. Module.patEscape(comment), '')
	-- local subbed = string.sub(line, indent + #comment - 2)
	if matchIndent then
		-- subbed = Module.getIndentString(line, indent) .. comment .. ' ' .. subbed
		subbed = string.match(line, "^%s*") .. comment .. ' ' .. string.gsub(line, "^%s*", '')
	else
		subbed = comment .. ' ' .. line
	end
	return subbed
end

function Module.patEscape(pattern)
	return pattern:gsub('([^%w])', '%%%1')
end

function Module.removeComment(line, comment, blockEnd)
	local removeEnd = blockEnd or false
	local subbed = line
	if 'string' == type(comment) then
		comment = {comment} end

	for i,cmt in ipairs(comment) do
		if Module.lineHasComment(line, cmt, removeEnd) then
			if removeEnd and Module.lineHasComment(line, cmt, removeEnd) then
				return string.sub(line, 1, #line - #cmt) end

			subbed = string.gsub(line, Module.patEscape(cmt) .. '%s*', '', 1)
			if line ~= subbed then
				break end
		end
	end
	return subbed
end

function Module.removePutRCiwSpace(number, subbed)
	if Module.lineIsWSpace(subbed) then
		Module.removeLine(number)
		return true
	else
		Module.putLine(number, subbed)
		return false
	end
end

function Module.lineHasComment(line, comment, blockEnd)
	if Module.lineIsWSpace(comment) then
		return false end
	local checkEnd = blockEnd or false
	local pattern = '^%s*' .. Module.patEscape(comment)
	if checkEnd then
		pattern = Module.patEscape(comment) .. '%s*$' end
	-- if checkEnd then
		-- For checking blockEnds of block comments
		-- return comment == string.sub(line, #line - #comment + 1)
	-- end
	return string.match(line, pattern) ~= nil

	-- local indent = Module.getIndent(line)
	-- local removedIndent = string.sub(line, indent)
	-- return string.sub(removedIndent, 1, #comment) == comment
end

function Module.getLine(number)
	return vim.api.nvim_buf_get_lines(0, number, number + 1, false)[1]
end

function Module.putLine(number, text)
	vim.api.nvim_buf_set_lines(0, number, number + 1, false, { text })
end

function Module.insertLine(number, text, matchIndent)
	if matchIndent then
		text = string.match(Module.getLine(number), "^%s*") .. text
	end
	vim.api.nvim_buf_set_lines(0, number, number, false, { text })
end

function Module.removeLine(number)
	vim.api.nvim_buf_set_lines(0, number, number + 1, false, {})
end

function Module.getSelectionCommentTypes(startRow, stopRow, cmt, blockStart, blockEnd)
	local containsComment = false
	local containsNoncomment = false
	local containsBlockStart = false
	local containsBlockEnd = false
	for n = startRow, stopRow do
		local currentLine = Module.getLine(n)
		if Module.lineHasComment(currentLine, cmt, false) then
			containsComment = true end
		if Module.lineHasComment(currentLine, blockStart, false) then
			containsBlockStart = true end
		if Module.lineHasComment(currentLine, blockEnd, true) then
			containsBlockEnd = true end
		if not Module.lineHasComment(currentLine, cmt, false) and not Module.lineIsWSpace(currentLine) then
			containsNoncomment = true end
	end
	return containsComment, containsNoncomment, containsBlockStart, containsBlockEnd
end

function Module.commentAddMultiline(startRow, stopRow, blockDecorator, blockStart, blockEnd)
	local startLine = Module.getLine(startRow)
	local startIndent = Module.getIndent(startLine)
	local endLine = Module.getLine(stopRow)
	local endIndent = Module.getIndent(endLine)
	Module.insertLine(stopRow + 1, Module.getIndentString(endLine, endIndent) .. blockEnd)
	Module.insertLine(startRow, Module.getIndentString(startLine, startIndent) .. blockStart)
	Module.commentAddNormal(startRow + 1, stopRow + 1, blockDecorator, true)
end

function Module.commentAddNormal(startRow, stopRow, cmt, matchIndent)
	if 0 == #cmt then
		return end
	for line = startRow, stopRow do
		local currentLine = Module.getLine(line)
		local newText = Module.addComment(currentLine, cmt, false, matchIndent)
		Module.putLine(line, newText)
	end
end

function Module.commentRemoveNormal(startRow, stopRow, comment)
	if 0 == #comment then
		return end
	for i = startRow, stopRow do
		local currentLine = Module.getLine(i)
		local subbed = Module.removeComment(currentLine, comment, false)
		Module.putLine(i, subbed)
	end
end

function Module.indexComment(startRow, stopRow, comment, lookatEnd)
	lookatEnd = lookatEnd or false
	for i = startRow, stopRow do
		local currentLine = Module.getLine(i)
		if Module.lineHasComment(currentLine, comment, lookatEnd) then
			return i end
	end
	return nil
end

function Module.commentRemoveMultiline(startRow, stopRow, blockDecorator, blockStart, blockEnd)
	local nStart = Module.indexComment(startRow, stopRow, blockStart, false)
	local nEnd = Module.indexComment(nStart, stopRow, blockEnd, true)
	local lineStart = Module.getLine(nStart)
	local subbedStart = Module.removeComment(lineStart, blockStart, false)
	local lineEnd = nil
	if nStart ~= nEnd then
		lineEnd = Module.getLine(nEnd)
		if Module.removePutRCiwSpace(nStart, subbedStart) then
			nEnd = nEnd - 1
			nStart = nStart - 1
		end
	else
		lineEnd = subbedStart
	end
	local subbedEnd = Module.removeComment(lineEnd, blockEnd, true)
	Module.removePutRCiwSpace(nEnd, subbedEnd)
	Module.commentRemoveNormal(nStart + 1, nEnd - 1, blockDecorator)
end

function Module.commentExtendMultiline(startRow, stopRow, blockDecorator, blockSE, isEnd)
	local n = Module.indexComment(startRow, stopRow, blockSE, isEnd)
	local line = Module.getLine(n)
	local subbed = Module.removeComment(line, blockSE, isEnd)
	if Module.removePutRCiwSpace(n, subbed) then
		stopRow = stopRow end
	if isEnd then
		Module.insertLine(stopRow, blockSE, true)
		Module.commentAddNormal(n, stopRow - 1, blockDecorator, true)
	else
		Module.insertLine(startRow, blockSE, true)
		Module.commentAddNormal(startRow + 1, n, blockDecorator, true)
	end
end

function Module.isWithinMultilineComment(startRow, stopRow, blockStart, blockEnd)
	local s, e = nil, nil
	for i = startRow, 0, -1 do
		local currentLine = Module.getLine(i)
		if Module.lineHasComment(currentLine, blockStart, false) then
			s = i
			break
		end
		if i ~= stopRow and Module.lineHasComment(currentLine, blockEnd, true) then
			break end
	end
	for i = stopRow, vim.api.nvim_buf_line_count(0) - 1 do
		local currentLine = Module.getLine(i)
		if Module.lineHasComment(currentLine, blockEnd, true) then
			e = i
			break
		end
		if i ~= startRow and Module.lineHasComment(currentLine, blockStart, false) then
			break end
	end
	return s, e
end

function Module.getCommentStyle(filetype)
	-- blockstatus:
	-- 	0 - Language does not support block comments (bash)
	-- 	1 - Language does support block comments (c, c++, css, javascript, ...)
	-- 	2 - Block comments are preferred for multiline comments
	-- 	3 - The only type of comment for the language is block. No inline comments allowed! (html)
	local cmt = ''
	local blockStart = ''
	local blockEnd = ''
	local blockDecorator = ''
	local blockStatus = 0
	if 'lua' == filetype then
		cmt = '--'
		blockStart = '--[' .. '['
		blockEnd = ']]'
		blockDecorator = ' -'
		blockStatus = 1
	elseif 'python' == filetype then
		cmt = '#'
		blockStart = '"""'
		blockEnd = '"""'
		-- blockDecorator = '#'
		blockStatus = 1
	elseif 'html' == filetype then
		-- cmt = '~'
		blockStart = '<!--'
		blockEnd = '-->'
		blockStatus = 3
	else
		cmt = '//'
		blockStart = '/*'
		blockEnd = ' */'
		blockDecorator = ' *'
		blockStatus = 2
	end
	return cmt, blockStart, blockEnd, blockDecorator, blockStatus
end

function Module.setup(opts)
	opts = opts or {}
	local keymap = opts.keymap or '<C-_>'

	vim.keymap.set({'n', 'i', 'v'}, keymap, Module.applyComments)
end

function Module.applyComments()
	-- Supply the adding of comments
	local cmt, blockStart, blockEnd, blockDecorator, blockStatus = Module.getCommentStyle(vim.bo.filetype)

	local startRow = vim.fn.line("v") - 1
	local stopRow = vim.fn.line('.') - 1
	if stopRow < startRow then
		startRow, stopRow = stopRow, startRow
	end
	local isMultilineComment = blockStatus >= 3
	if stopRow - startRow >= 1 and 2 == blockStatus then
		isMultilineComment = true
	end

	local containsComment, containsNoncomment, containsBlockStart, containsBlockEnd = Module.getSelectionCommentTypes(startRow, stopRow, cmt, blockStart, blockEnd)
	if not containsBlockStart and not containsBlockEnd then
		local s, e = Module.isWithinMultilineComment(startRow, stopRow, blockStart, blockEnd)
		if nil ~= s and nil ~= e then
			Module.commentRemoveMultiline(s, e, blockDecorator, blockStart, blockEnd)
		elseif containsComment and not containsNoncomment then
			Module.commentRemoveNormal(startRow, stopRow, cmt)
		elseif isMultilineComment then
			Module.commentAddMultiline(startRow, stopRow, blockDecorator, blockStart, blockEnd)
		elseif containsNoncomment then
			Module.commentAddNormal(startRow, stopRow, cmt, true)
		end
	else
		if 0 == startRow - stopRow then
			local s, e = Module.isWithinMultilineComment(startRow, stopRow, blockStart, blockEnd)
			if nil ~= s and nil ~= e then
				Module.commentRemoveMultiline(s, e, blockDecorator, blockStart, blockEnd) end
		elseif containsBlockStart and containsBlockEnd then
			Module.commentRemoveMultiline(startRow, stopRow, blockDecorator, blockStart, blockEnd)
		elseif containsBlockStart then
			Module.commentExtendMultiline(startRow, stopRow, blockDecorator, blockStart, false)
		else
			Module.commentExtendMultiline(startRow, stopRow, blockDecorator, blockEnd, true)
		end
	end

	-- For exiting visual mode
	vim.api.nvim_feedkeys(vim.keycode'<Esc>', 'n', false)
end

return Module
