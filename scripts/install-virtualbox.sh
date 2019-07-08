#!/usr/bin/bash

echo -e "\n[seblu]\nServer = https://al.seblu.net/$repo/$arch" | sudo tee -a /etc/pacman.conf
yes | sudo pacman -S virtualbox virtualbox-guest-iso virtualbox-ext-oracle virtualbox-host-dkms
