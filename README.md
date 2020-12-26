# nvim-blame-line

A small plugin that uses neovims virtual text to print git blame info at the end of the current line.

Also supports showing blame below the current window, for normal vim users.

nvim-blame-line prints author, date and summary of the commit belonging to the line underneath the cursor.
Just like a real IDE!

## Installation

Use a plugin manager like [vim-plug](https://github.com/junegunn/vim-plug)

```
Plug 'tveskag/nvim-blame-line'
```

## Usage

![Example gif](https://github.com/tveskag/nvim-blame-line/blob/master/img/example.gif "Example gif")

### Commands

The plugin is exposed through these commands:

- `EnableBlameLine`
- `DisableBlameLine`
- `ToggleBlameLine`
- `SingleBlameLine`

Example mapping:

```vim
nnoremap <silent> <leader>b :ToggleBlameLine<CR>
```

Use autocmd to enable on startup:

```vim
autocmd BufEnter * EnableBlameLine
```

### Options
 
```vim
" Show blame info below the statusline instead of using virtual text
let g:blameLineUseVirtualText = 0

" Specify the highlight group used for the virtual text ('Comment' by default)
let g:blameLineVirtualTextHighlight = 'Question'

" Change format of virtual text ('%s' by default)
let g:blameLineVirtualTextFormat = '/* %s */'

" Customize format for git blame (Default format: '%an | %ar | %s')
let g:blameLineGitFormat = '%an - %s'
" Refer to 'git-show --format=' man pages for format options)
```
