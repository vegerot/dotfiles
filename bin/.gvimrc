if filereadable(expand('~/bin/.gvimrc'))
    so ~/bin/gvimrc
else
    echo "Can't find ~/bin/.gvimrc"
    syntax on
    source /usr/local/Cellar/macvim/HEAD-dc07a14/MacVim.app/Contents/Resources/vim/gvimrc
endif

