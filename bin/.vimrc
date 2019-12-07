if filereadable(expand('~/bin/vimrc'))
    so ~/bin/vimrc
else
    echo "Can't find ~/bin/vimrc"
    syntax on
    source /usr/local/Cellar/macvim/HEAD-dc07a14/MacVim.app/Contents/Resources/vim/vimrc
endif

