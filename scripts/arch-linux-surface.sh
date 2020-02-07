#!/usr/bin/bash

if [ "$EUID" -eq 0 ]
  then echo "Do not run this script as root."
  exit
fi

cache_folder=.cache
patches_repository=git://github.com/qzed/linux-surface.git
patches_src_folder=linux-surface
firmware_src_folder="$cache_folder/$patches_src_folder/firmware"
libwacom_repository=git://github.com/qzed/libwacom-surface.git
libwacom_src_folder=libwacom-surface

############################### SETUP ###############################

cd /srv/git && git clone https://github.com/dmhacker/arch-linux-surface.git
cd arch-linux-surface

echo "Updating cache ..."
mkdir -p $cache_folder
cd $cache_folder

# Fetch patches repository
if [ -d $patches_src_folder ]; then
  cd $patches_src_folder && git pull && cd ..
else
  git clone $patches_repository $patches_src_folder
fi

# Fetch libwacom repository
if [ -d $libwacom_src_folder ]; then
  cd $libwacom_src_folder && git pull && cd ..
else
  git clone $libwacom_repository $libwacom_src_folder
fi

cd ..

############################### INSTALLATION ###############################

# Prompt for installation of root files
echo "Unpacking files to / ..."
sudo cp -r $cache_folder/$patches_src_folder/root/etc/* /etc
sudo mkdir -p /lib/systemd/system-sleep
sudo cp $cache_folder/$patches_src_folder/root/lib/systemd/system-sleep/sleep /lib/systemd/system-sleep
echo "Making /lib/systemd/system-sleep/sleep executable ..."
sudo chmod a+x /lib/systemd/system-sleep/sleep
echo "Done copying config files."

# Prompt for modules upload & mkinitcpio rebuild
modules=$(echo "MODULES=($(grep -v '^#' base/templates/modules))" | tr "\n" " " | sed 's/ *$//g')
echo "$modules will be added to /etc/mkinitcpio.conf."
sudo sed -i.bak -E "s/^MODULES=(.*).*/$modules/" /etc/mkinitcpio.conf
sudo mkinitcpio
echo "Done fixing mkinitcpio.conf."

echo "Copying files to /lib/firmware ..."
sudo mkdir -p /lib/firmware
sudo cp -rv $firmware_src_folder/* /lib/firmware
echo "Done installing firmware."
