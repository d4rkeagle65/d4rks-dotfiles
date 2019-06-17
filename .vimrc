if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()

Plug 'vim-perl/vim-perl'
"Plug 'https://github.com/danilo-augusto/vim-afterglow.git'
Plug 'crusoexia/vim-monokai'

call plug#end()

"colorscheme afterglow
colorscheme monokai

syntax enable
set number
set incsearch
set hlsearch
set laststatus=2
