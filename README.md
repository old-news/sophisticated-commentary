# Sophisticated Commentary
I created this NeoVim plugin because I liked the VScode Ctrl+/ comments. With NeoVim, you have to type a few more keys, which is unnacceptable. Therefore, this pluginwas made. Please enjoy

## Installation
In your init.lua, add the following:
<ul>
    <li>In your vim.pack list, add this page's url</li>
    <li>Add `require('sophisticated-commentary').setup {}`. </li>
</ul>
You're all set!

## Usage
Simply type <Ctrl+/> in any mode to comment/uncomment the current line.<br>
If you're in visual mode, the currently selected block will be commented/uncommented instead.
