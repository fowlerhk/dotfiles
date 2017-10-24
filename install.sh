#!/bin/bash
#
# Helper script to setup symlinks for dotfiles and bin directory.
#

DIR=~/dotfiles
OLDDIR=~/dotfiles_old

mkdir -p $OLDDIR/bin
cd $DIR

echo "Install ~/bin symlinks..."
mkdir -p ~/bin
for file in bin/*; do
   mv ~/$file $OLDDIR/bin
   ln -sv $DIR/$file ~/$file
done

echo "Install dotfile symlinks..."
DOTFILES="bash_aliases gitconfig vimrc"
for file in $DOTFILES; do
   mv ~/.$file $OLDDIR
   ln -sv $DIR/$file ~/.$file
done

# Install the Vim Vundle plugin
mv ~/.vim $OLDDIR
mkdir -p ~/.vim/bundle
export GIT_SSL_NO_VERIFY=true
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall
