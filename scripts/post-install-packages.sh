#!/bin/bash

pkgs=$(</srv/git/d4rks-dotfiles/configs/package_install_list.txt)
sudo pacman --noconfirm -S $pkgs
