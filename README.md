# 🫵 blame.nvim

**blame.nvim** is a [fugitive.vim](https://github.com/tpope/vim-fugitive) style git blame visualizer for Neovim.

Window:
<img width="1499" alt="window_blame_cut" src="https://github.com/FabijanZulj/blame.nvim/assets/38249221/3a3c0a87-8f6b-461a-9ea7-cd849c2de326">

Virtual:
<img width="1495" alt="virtual_blame_cut" src="https://github.com/FabijanZulj/blame.nvim/assets/38249221/8c17c8ae-901e-4183-ac73-c62bb4a259dc">

_Same commits are highlighted in the same color_

## Installation

```lua
require("lazy").setup({
    {
        "seblj/blame.nvim",
        config = function()
            require("blame").setup()
        end,
    },
})
```

## Usage

The following commands are used:

- `ToggleBlame [mode]` - Toggle the blame window or virtual text. If no mode is provided it opens the `window` type

There are two builtin modes:

- `window` - fugitive style window to the left of the window
- `virtual` - blame shown in a virtual text floated to the right

## Configuration

These are the fields you can configure by passing them to the `require('blame').setup({})` function:

- `date_format` - string - Pattern for the date (default: "%d.%m.%Y")
- `views` - table<string, BlameView> - A table for configuring your own view for blame

## Advanced

### Configuring your own view

It is possible to configure your own view of git blame. To do this, you need to
implement a class that contains three methods. `new`, `open` and `close`. You
may then pass that class in as a config option under a key in the views-table.
Check out
[this](https://github.com/seblj/blame.nvim/blob/main/lua/blame/virtual_blame.lua) for
an example of how virtual text is implemented.

- The `new` method takes the config table as an argument and should return a
  metatable.
- The `open` method takes the parsed blamed lines as an argument, and should
  display them however you want
- The `close` method takes no argument, and is meant to close everything
