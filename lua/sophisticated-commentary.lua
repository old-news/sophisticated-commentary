local Module = {}
Module.languageComments = {}

function Module.getLeadingWSpace(line)
	return line:match('^%s*')
end

function Module.stringIsWSpace(line)
	return 0 == #string.gsub(line, '%s*', '')
end

function Module.addComment(line, comment, lookatEnd, commentMatchesIndentation)
	lookatEnd = lookatEnd or false
	local matchIndent = commentMatchesIndentation and true
	if Module.lineHasComment(line, comment, lookatEnd) or Module.stringIsWSpace(line) then
		return line end

	if lookatEnd then
		return line .. ' ' .. comment end

	if matchIndent then
		-- The below line makes comment string have the same indent as the text instead of being left-justified
		return string.match(line, "^%s*") .. comment .. ' ' .. string.gsub(line, "^%s*", '')
	else
		return comment .. ' ' .. line
	end
end

function Module.patEscape(pattern)
	return pattern:gsub('([^%w])', '%%%1')
end

function Module.removeComment(line, comment, lookatEnd)
	lookatEnd = lookatEnd or false
	local subbed = line
	if 'string' == type(comment) then
		comment = {comment} end

	for i,cmt in ipairs(comment) do
		if Module.lineHasComment(line, cmt, lookatEnd) then
			if lookatEnd and Module.lineHasComment(line, cmt, lookatEnd) then
				return string.sub(line, 1, #line - #cmt) end

			subbed = string.gsub(line, Module.patEscape(cmt) .. '%s*', '', 1)
			if line ~= subbed then
				break end
		end
	end
	return subbed
end

function Module.removePutRCiwSpace(number, subbed)
	-- Remove comment from line
	-- If line is empty, remove
	-- Otherwise, putLine
	if Module.stringIsWSpace(subbed) then
		Module.removeLine(number)
		return true
	else
		Module.putLine(number, subbed)
		return false
	end
end

function Module.lineHasComment(line, cmt, lookatEnd)
	if Module.stringIsWSpace(cmt) then
		return false end
	local pattern = nil
	if lookatEnd then
		pattern = Module.patEscape(cmt) .. '%s*$'
	else
		pattern = '^%s*' .. Module.patEscape(cmt)
	end
	return string.match(line, pattern) ~= nil
end

function Module.getLine(number)
	return vim.api.nvim_buf_get_lines(0, number, number + 1, false)[1]
end

function Module.putLine(number, text)
	vim.api.nvim_buf_set_lines(0, number, number + 1, false, { text })
end

function Module.insertLine(number, text, matchIndent)
	if matchIndent then
		text = string.match(Module.getLine(number), "^%s*") .. text end
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
		if not Module.lineHasComment(currentLine, cmt, false) and not Module.stringIsWSpace(currentLine) then
			containsNoncomment = true end
	end
	return containsComment, containsNoncomment, containsBlockStart, containsBlockEnd
end

function Module.commentAddMultiline(startRow, stopRow, blockDecorator, blockStart, blockEnd)
	local startLine = Module.getLine(startRow)
	local endLine = Module.getLine(stopRow)
	Module.insertLine(stopRow + 1, Module.getLeadingWSpace(endLine) .. blockEnd)
	Module.insertLine(startRow, Module.getLeadingWSpace(startLine) .. blockStart)
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
	if 'table' ~= type(comment) then
		comment = { comment } end
	if 0 == #comment[0] then
		return end
	for i = startRow, stopRow do
		local currentLine = Module.getLine(i)
		local subbed = Module.removeComment(currentLine, comment, false)
		Module.putLine(i, subbed)
	end
end

function Module.indexComment(startRow, stopRow, cmt, lookatEnd)
	-- Return row between 'startRow' and 'stopRow' where 'comment' appears
	lookatEnd = lookatEnd or false
	for i = startRow, stopRow do
		local currentLine = Module.getLine(i)
		if Module.lineHasComment(currentLine, cmt, lookatEnd) then
			return i end
	end
	return nil
end

function Module.commentRemoveMultiline(startRow, stopRow, blockDecorator, blockStart, blockEnd)
	-- Remove multiline comment which is entirely between 'startRow' and 'stopRow'
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
	-- Extend multiline comment
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

function Module.getOuterMultilineCommentRows(startRow, stopRow, blockStart, blockEnd)
	-- Returns the opening and closing row indexes if the selection is enclosed within a multiline comment
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

function Module.getCommentStyle(ft)
	-- blockstatus (lc[5]):
	-- 	0 - Language does not support block comments (bash, asm)
	-- 	1 - Language does support block comments (c, c++, css, javascript, ...)
	-- 	2 - Block comments are preferred for multiline comments (c-languages)
	-- 	3 - The only type of comment for the language is block. No inline comments allowed! (html)
	local lc = Module.languageComments[ft] or Module.languageComments['default']
	return lc[1] or '', lc[2] or 0, lc[3] or '', lc[4] or '', lc[5] or ''
end

function Module.setup(opts)
	opts = opts or {}
	opts.languages = opts.languages or {}
	local keymap = opts.keymap or '<C-_>'
	vim.keymap.set({'n', 'i', 'v'}, keymap, Module.applyComments)

	Module.languageComments = {
		-- {comment, blockStatus, blockStart, blockEnd, blockDecorator}
		default = {'//', 2, '/*', ' */', ' *'},
		ada = {'--', 0},
		asm = {';', 0},
		css = {'//', 3, '/*', ' */', ' *'},
		dockerfile = {'#'},
		elixir = {'#', 1, '"""', '"""'},
		elm = {'--', 2, '{', '}'},
		env = {'#', 0},
		haskell = {'--', 0},
		html = {'', 3, '<!--', '-->'},
		lua = {'--', 1, '--[' .. '[', ']]'},
		python = {'#', 1, '"""', '"""'},
		sh = {'#', 0},
		perl = {'#', 2, '=', '=cut'},
		ps1 = {'#', 2, '<#', '#>'},
		r = {'#', 0},
		ruby = {'#', 2, '=begin', '=end'},
		sql = {'--', 0},
		php = {'#', 2, '/*', ' */', ' *'},
		xml = {'', 3, '<!--', '-->'},
		yaml = {'#', 0},
	}
	Module.blockCommentThreshold = opts.blockCommentThreshold or 2
	if Module.blockCommentThreshold < 1 then
		Module.blockCommentThreshold = 1 end

	for key, value in pairs(opts.languages) do
		Module.languageComments[key] = value
	end

	for key, _ in pairs(Module.languageComments) do
		if opts.noBlockDecorators then
			Module.languageComments[key][5] = nil end
	end
end

function Module.applyComments()
	-- Supply the adding of comments
	local cmt, blockStatus, blockStart, blockEnd, blockDecorator = Module.getCommentStyle(vim.bo.filetype)

	local startRow = vim.fn.line("v") - 1
	local stopRow = vim.fn.line('.') - 1
	if stopRow < startRow then
		startRow, stopRow = stopRow, startRow
	end
	local isMultilineComment = blockStatus >= 3
	if stopRow - startRow >= 1 and blockStatus >= Module.blockCommentThreshold - 1 and blockStatus ~= 0 then
		isMultilineComment = true
	end

	local containsComment, containsNoncomment, containsBlockStart, containsBlockEnd = Module.getSelectionCommentTypes(startRow, stopRow, cmt, blockStart, blockEnd)
	if not containsBlockStart and not containsBlockEnd then
		local s, e = Module.getOuterMultilineCommentRows(startRow, stopRow, blockStart, blockEnd)
		if s and e then
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
			local s, e = Module.getOuterMultilineCommentRows(startRow, stopRow, blockStart, blockEnd)
			if s and e then
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
