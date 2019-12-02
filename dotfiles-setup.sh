#!/usr/bin/bash

[ -d /home/${1}/.local ] || mkdir -p /home/${1}/.local
mkdir -p /home/${1}/.local/share
mkdir -p /home/${1}/.config
chown ${1}.users -R /home/${1}/.local
chown ${1}.users -R /home/${1}/.config

ln -sf /srv/git/d4rks-dotfiles/.bash_aliases /home/${1}/.bash_aliases
ln -sf /srv/git/d4rks-dotfiles/.bash_functions /home/${1}/.bash_functions
ln -sf /srv/git/d4rks-dotfiles/.bash_lessfilter /home/${1}/.bash_lessfilter
ln -sf /srv/git/d4rks-dotfiles/.bash_profile /home/${1}/.bash_profile
ln -sf /srv/git/d4rks-dotfiles/.bashrc /home/${1}/.bashrc
ln -sf /srv/git/d4rks-dotfiles/.makepkg.i686.conf /home/${1}/.makepkg.i686.conf
ln -sf /srv/git/d4rks-dotfiles/.vimrc /home/${1}/.vimrc
ln -sf /srv/git/d4rks-dotfiles/.xinitrc /home/${1}/.xinitrc

ln -sf /srv/git/d4rks-dotfiles/configs/termite/termite /home/${1}/.config/termite

[ -d /etc/pacman.d/hooks ] || sudo mkdir -p /etc/pacman.d/hooks
sudo ln -sf /srv/git/d4rks-dotfiles/configs/cryptboot/98-cryptboot-pacman.hook /etc/pacman.d/hooks/98-cryptboot-pacman.hook

mkdir -p /home/${1}/.config/conky
chown -R ${1}.users /home/${1}/.config/conky
ln -sf /srv/git/d4rks-dotfiles/configs/conky/conky.conf /home/${1}/.config/conky/conky.conf
ln -sf /srv/git/d4rks-dotfiles/configs/conky/today.py /home/${1}/.config/conky/today.py

mkdir -p /home/${1}/.config/ownCloud
chown -R ${1}.users /home/${1}/.config/ownCloud
ln -sf /srv/git/d4rks-dotfiles/configs/ownCloud/owncloud.cfg /home/${1}/.config/ownCloud/owncloud.cfg

mkdir -p /home/${1}/.config/i3
chown -R ${1}.users /home/${1}/.config/i3
ln -sf /srv/git/d4rks-dotfiles/configs/i3/config /home/${1}/.config/i3/config
ln -sf /srv/git/d4rks-dotfiles/configs/i3/i3lock.sh /home/${1}/.config/i3/i3lock.sh

mkdir -p /home/${1}/.config/trizen
chown -R ${1}.users /home/${1}/.config/trizen
ln -sf /srv/git/d4rks-dotfiles/configs/trizen/trizen.conf /home/${1}/.config/trizen/trizen.conf

chown -R ${1}.users /home/${1}/
