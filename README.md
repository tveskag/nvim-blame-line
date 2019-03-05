# nvim-blame-line
A small plugin that uses neovims virtual text, to print git blame info at the end of the current line.

nvim-blame-line prints author, date, and summary of the commit, that the line underneath the cursor belongs to.
Just like a real IDE!

the plugin is exposed through the functions:
EnableBlameLine
DisableBlameLine
ToggleBlameLine

Usage:
fx:
nmap <expr> <leader>c b:ToggleBlameLine()

At the moment this depends on https://github.com/tpope/vim-fugitive to set b:git_dir
