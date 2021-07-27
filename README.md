# Fold.nvim

A simple utility tool for reducing the uninteresting parts of the buffer while
searching.


## Installation

### Packer.nvim

```lua
use('mortepau/fold.nvim')
```

### vim-plug

```vim
Plug 'mortepau/fold.nvim'
```

## Configuration

```lua
require('fold').setup({
  -- Key used to start the fold "mode"
  enable = 'zz',
  -- Key used to toggle the folding of the fold under the cursor
  toggle = '<CR>',
  -- Lines of context on each side of the match
  context = 5,
  -- Number of trailing characters in the foldtext
  tail = 100,
})
```

## Usage

The functionality is really simple as it uses only two (2) keymaps which can be
modified to suit your desire.

To start folding based on your current search simply press `zz` which will fold
away everything except for the matches and its surrounding context.
To exit the mode, press `zz` again.

To open or close a fold use `<CR>` (Enter).

The fold will close when the cursor is outside the range of lines.


