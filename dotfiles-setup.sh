#!/usr/bin/bash

rm /home/${1}/.bash_aliases
rm /home/${1}/.bash_functions
rm /home/${1}/.bash_lessfilter
rm /home/${1}/.bash_profile
rm /home/${1}/.bashrc
rm /home/${1}/.makepkg.i686.conf
rm /home/${1}/.vimrc

ln -s /srv/git/d4rks-dotfiles/.bash_aliases /home/${1}/.bash_aliases
ln -s /srv/git/d4rks-dotfiles/.bash_functions /home/${1}/.bash_functions
ln -s /srv/git/d4rks-dotfiles/.bash_lessfilter /home/${1}/.bash_lessfilter
ln -s /srv/git/d4rks-dotfiles/.bash_profile /home/${1}/.bash_profile
ln -s /srv/git/d4rks-dotfiles/.bashrc /home/${1}/.bashrc
ln -s /srv/git/d4rks-dotfiles/.makepkg.i686.conf /home/${1}/.makepkg.i686.conf
ln -s /srv/git/d4rks-dotfiles/.vimrc /home/${1}/.vimrc

ln -s /srv/git/d4rks=dotfiles/configs/cryptboot/98-cryptboot-pacman.hook /etc/pacman.d/hooks/98-cryptboot-pacman.hook
