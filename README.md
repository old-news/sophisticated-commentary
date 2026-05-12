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

## Customization
Currently, the only thing you can customize is the keymap. To do so, set the keymap option during setup:

### vim.pack

```lua
require('sophisticated-commentary').setup({
    keymap='<C-3>'
})
```

### lazy.vim

```lua
opts = {
    keymap = "<C-3>"
}
```

---

This example maps `Ctrl+3` to the comment function.
