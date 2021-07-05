# taskell.nvim
[taskell](https://github.com/smallhadroncollider/taskell) preview inside neovim
## Installation
_**NOTE: This plugin requires Neovim 0.5**_

with [packer.nvim](https://github.com/wbthomason/packer.nvim)

`use {'romariorobby/taskell.nvim'}`

with [vim-plug](https://github.com/junegunn/vim-plug)

`Plug 'romariorobby/taskell.nvim'`

## Usage
`:Taskel (md file)`

- Pressing `q` close the window like on taskell
- No _path argument_ will uses current path

**Mapping Example**

**Lua**

`
vim.api.nvim_set_keymap('n', '<leader>tt', ':Taskel<CR>',{ nnoremap = true, silent = true})
`

**vimscript**

`nmap <leader>tt :Taskel<CR>`
