# Sophisticated Commentary
I created this NeoVim plugin because I liked the VScode `Ctrl+/` keymap to comment/uncomment code. With NeoVim, you have to type a few more keys, which is unnacceptable. Therefore, this plugin was made. Please enjoy!

## Installation
In your `init.lua` file (located in your `~/.config/nvim/` directory), you must install and set up the package.<br>

### Using vim.pack
Add this page's URL to your vim.pack list, then set up the package:
```lua
vim.pack.add({
    'https://github.com/old-news/sophisticated-commentary'
})
require('sophisticated-commentary').setup()
```

### Using lazy.vim
```lua
{
    "old-news/sophisticated-commentary",
    opts = {}
}
```

---

You're all set!

## Usage
Simply type `Ctrl+/` in any mode to comment/uncomment the current line.
If you're in visual mode, the currently selected block will be commented/uncommented instead.

## Customizations
You can apply the following customizations:
<ol>
    <li>Set the keymap for applying comments</li>
    <li>Remove comment decorators</li>
    <li>Set the comment text for specific filetypes</li>
    <li>Set how block comments are applied</li>
</ol>

### 1
Set the keymap for applying comments:

#### Using vim.pack

```lua
require('sophisticated-commentary').setup({
    keymap='<C-3>'
})
```

#### Using lazy.vim

```lua
opts = {
    keymap = "<C-3>"
}
```

---

This example maps `Ctrl+3` to the comment function.

### 2
Remove comment decorators<br>
To remove comment decorators, simply set the noBlockDecorators value to false:
```lua
require('sophisticated-commentary').setup({
    noBlockDecorators = true
})
```
The '*'s (asterisks) in the example below which are not on the first and last lines are block decorators
```
/* The beginning of this line is the block comment start, not a comment decorator
 * This line starts with a comment decorator
 * Same for this line. The line below is the block comment end
 */
```

### 3
Set the comment text for specific filetypes<br>
If the language you're using doesn't have the correct text for comments, you can manually change it. Here's an example using `vim.pack`

```lua
require('sophisticated-commentary').setup({
    languages = {
        foo = {'!', 1, '<%', ' %>', ' %'}
    }
})
```

This example says that files of type 'foo' (ends in .foo) have inline comments that start with '!', block comments that begin with '<%' and end with '%>', and have a comment decorator of '%'. The block comment ending and comment decorator have spaces so that they line up when the block comment is applied. Compare the examples below:

```
/*
* This is an example
* of bad spacing.
*/
```
```
/*
 * This is an example 
 * of good spacing.
 */
```
Notice that the asterisks are aligned in the second example.<br>
The second value in this table is '1', which is the blockCommentThreshold for that filetype. blockCommentThreshold is explained below at number 4.<br>
To set the default commenting style, simply set the 'default' option in languages:
```lua
require('sophisticated-commentary').setup({
    languages = {
        default = {'//', 2, '/*', ' */', ' *'}
    }
})
```

### 4
Set how block comments are applied
This determines when block comments are applied instead of inline comments. This is set by the blockCommentThreshold value:
```lua
require('sophisticated-commentary').setup({
    blockCommentThreshold = 1
})
```
There are 4 different values for the block comment threshold:<br>
&nbsp;&nbsp;&nbsp;&nbsp;0 - Never do a block comment (language doesn't have block comments)
&nbsp;&nbsp;&nbsp;&nbsp;1 - The language supports multiline docstrings, but not block comments (python)
&nbsp;&nbsp;&nbsp;&nbsp;2 - The language support block comments (c, javascript)
&nbsp;&nbsp;&nbsp;&nbsp;3 - The language does not support inline comments, so only block comments are allowed (html, xml)

Every language with a blockCommentThreshold at least as large as the one you set in setup will always do block comments. The languages with a blockCommentThreshold exactly one below the one you set will only do block comments for multiline comments. Languages with a blockCommentThreshold of `0` will never apply block comments. Languages with a blockCommentThreshold will always apply block comments. The default `blockCommentThreshold` is `2`.<br>
By default, block comments will be applied to multiline C comments, but not to multiline python comments. This behavior is displayed below:
```python
# Here is a
# comment that
# spans
# multiple lines
```
```c
/*
 * Here is a
 * comment that
 * spans
 * multiple lines
 */
```
If you want to have docstrings automatically applied for multiline python comments, you can either change the python comments style, as explained in option 3, or you can change the `blockCommentThreshold`. Below is how the exact same text would be commented if you set `blockCommentThreshold` to `1`:
```python
"""
Here is a
comment that
spans
multiple lines
"""
```
