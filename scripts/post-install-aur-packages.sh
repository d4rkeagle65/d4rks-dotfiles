#!/bin/bash

pkgs=$(</srv/git/d4rks-dotfiles/configs/aur_package_install_list.txt)
trizen --skipinteg --noconfirm -S $pkgs

mkdir ~/.ownCloud
