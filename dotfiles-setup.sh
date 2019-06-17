#!/usr/bin/bash

ln -sf /srv/git/d4rks-dotfiles/.bash_aliases /home/${1}/.bash_aliases
ln -sf /srv/git/d4rks-dotfiles/.bash_functions /home/${1}/.bash_functions
ln -sf /srv/git/d4rks-dotfiles/.bash_lessfilter /home/${1}/.bash_lessfilter
ln -sf /srv/git/d4rks-dotfiles/.bash_profile /home/${1}/.bash_profile
ln -sf /srv/git/d4rks-dotfiles/.bashrc /home/${1}/.bashrc
ln -sf /srv/git/d4rks-dotfiles/.makepkg.i686.conf /home/${1}/.makepkg.i686.conf
ln -sf /srv/git/d4rks-dotfiles/.vimrc /home/${1}/.vimrc
ln -sf /srv/git/d4rks-dotfiles/.xinitrc /home/${1}/.xinitrc

mkdir -p /etc/pacman.d/hooks
ln -sf /srv/git/d4rks-dotfiles/configs/cryptboot/98-cryptboot-pacman.hook /etc/pacman.d/hooks/98-cryptboot-pacman.hook

mkdir -p /home/${1}/.config/i3
chown ${1}.users /home/${1}/.config/i3
ln -sf /srv/git/d4rks-dotfiles/configs/i3/config /home/${1}/.config/i3/config

mkdir -p /home/${1}/.config/trizen
chown ${1}.users /home/${1}/.config/trizen
ln -sf /srv/git/d4rks-dotfiles/configs/trizen/trizen.conf /home/${1}/.config/trizen/trizen.conf

chown ${1}.users /home/${1}/.config
