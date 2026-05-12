# Sophisticated Commentary
I created this NeoVim plugin because I liked the VScode Ctrl+/ comments. With NeoVim, you have to type a few more keys, which is unnacceptable. Therefore, this pluginwas made. Please enjoy

## Installation
In your init.lua file (located in your ~/.config/nvim/ directory), add the following:
<ul>
    <li>In your vim.pack list, add this page's url:<br>
        ```lua
        vim.pack.add({
            'https://github.com/old-news/sophisticated-commentary'
        })
        ```
    </li>
    <li>Add ```require('sophisticated-commentary').setup {}```. </li>
</ul>
So, the only necessary code is all below:
```lua
    vim.pack.add({
        'https://github.com/old-news/sophisticated-commentary'
    })
    require('sophisticated-commentary').setup {}
```
You're all set!

## Usage
Simply type <Ctrl+/> in any mode to comment/uncomment the current line.<br>
If you're in visual mode, the currently selected block will be commented/uncommented instead.

## Customization
Currently, the only thing you can customize is the keymap. To do so, set the keymap option during setup:
```lua
    require('sophisticated-commentary').setup {
        keymap='<C-3>'
    }
```
This example maps `<Ctrl+3>` to the comment function.
