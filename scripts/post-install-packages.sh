#!/bin/bash

pkgs=$(</srv/git/d4rks-dotfiles/configs/package_install_list.txt)
sudo pacman --noconfirm -S $pkgs

mkdir -p /home/dhardin/.ownCloud/Davids/.laptopSetup/
chown dhardin.users -R /home/dhardin/.ownCloud/
owncloudcmd -h --user dhardin --password ${1} --non-interactive --trust $HOME/.ownCloud/Davids/.laptopSetup/ https://owncloud.axxiscom.com/remote.php/webdav/Davids/.laptopSetup/
for filename in /home/dhardin/.ownCloud/Davids/.laptopSetup/*.sh; do
  sed -i 's/\r$//' {filename}
done
sh /home/dhardin/.ownCloud/Davids/.laptopSetup/owncloud_laptopSetupScript.sh
