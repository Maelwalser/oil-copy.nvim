# oil-copy.nvim
An extension for [stevearc/oil.nvim](https://github.com/stevearc/oil.nvim) that allows you to copy the contents of one or more files, or the recursive contents of entire directories, directly to your system clipboard.
## Features

https://github.com/user-attachments/assets/a8955a35-c289-4924-9154-6bb35b6d0b87

- **Copy Single Files**: In normal mode, place your cursor over a file and copy its entire content to the system clipboard (+ register).

- **Copy Directories**: In normal mode, place your cursor over a directory to recursively find all files within it, concatenate their contents, and copy the result to the clipboard.

- **Copy Visual Selections**: In visual mode, select multiple files and/or directories. The plugin will copy the contents of all selected files and all files found recursively within any selected directories.

- **Contextual Headers**: When copying multiple files (either from a directory or a visual selection), the file path of each file is added as a comment (-- /path/to/file) above its content, making the combined text easy to navigate.

## Requirements
- neovim/nvim-lsp (v0.8+)

- stevearc/oil.nvim

## Installation & Configuration
Here is an example using lazy.nvim.

```lua
{
  "maelwalser/oil-copy.nvim",
  dependencies = { "stevearc/oil.nvim" },
  opts = {
    -- You can customize the keymap here
    -- keymap = "<leader>p" -- Uncomment and change to your preferred key
  },
  config = function()
    require("oil-copy").setup()
  end,
}
```

The plugin is enabled by calling the setup() function. The default keymap for both normal and visual mode is <leader>cf.

## Usage
Once installed, the plugin sets up keymaps within any oil buffer:

- **Normal Mode**:

  - Place your cursor on a file and press <leader>cf (or your custom keymap) to copy its contents.

  - Place your cursor on a directory and press <leader>cf to copy the recursive contents of all files within that directory.

- **Visual Mode**:

  - Select one or more files and/or directories and press <leader>cf.

  - This will copy the contents of all selected files and the recursive contents of all files within any selected directories.
