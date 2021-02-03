#!/usr/bin/env bash
## https://sandrokeil.github.io/yubikey-full-disk-encryption-secure-boot-uefi/
## https://wiki.archlinux.org/index.php/Rng-tools

LOGFILENAME=arch-install.log
LOGFILE=/root/${LOGFILENAME}
exec > >(tee -i ${LOGFILE})
exec 2>&1

# Remounts cowspace with 1G of space from the extra packages we need to setup the env
mount -o remount,size=1G /run/archiso/cowspace

pacman -Syy
yes | pacman -Sy pacman-contrib dialog git make pcsc-tools
systemctl start pcscd.service

# Prompts
EMAIL='dhardin@hardinsolutions.net'
FNAME=David
LNAME=Hardin
ai_hostname=$(dialog --stdout --clear --inputbox "Enter the hostname:" 8 38)
ai_username=$(dialog --stdout --clear --inputbox "Enter your account name:" 8 38)
ai_password=$(dialog --stdout --clear --passwordbox "Enter your password:" 8 38)
ai_password2=$(dialog --stdout --clear --passwordbox "Confirm your password:" 8 38)

ai_devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop|sr0" | tac)
ai_device=$(dialog --stdout --clear --menu "Select installation disk" 0 0 0 ${ai_devicelist})

clear

ai_partIdent=""
if [[ $ai_device =~ "nvme" ]]; then
	ai_partIdent="p"
fi

if ! ping -c 1 "google.com" >/dev/null 2>&1; then
	echo "Cant connect to the internet."
	exit
fi

# Waits for IP to be assigned from DHCP, keeps checking and looping until google.com is pingable
ping_cancelled=0                                            # Keep track of whether the loop was cancelled, or succeeded
until ping -c1 "google.com" >/dev/null 2>&1; do :; done &   # The "&" backgrounds it
trap "kill $!; ping_cancelled=1" SIGINT
wait $!                                                     # Wait for the loop to exit, one way or another
trap - SIGINT                                               # Remove the trap, now we're done with it
if [ $ping_cancelled -eq 1 ]; then
  echo "Ctrl+C Detected."
  exit;
fi

# Ranks the mirrors for the fastest 5
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.rank
curl -s "https://archlinux.org/mirrorlist/?country=US&protocol=https&ip_version=4&use_mirror_status=on" -o /root/mirrorlist.new
sed -e 's/^#Server/Server/' -e '/^#/d' -i /root/mirrorlist.new
rankmirrors -n 5 /root/mirrorlist.new > /etc/pacman.d/mirrorlist
pacman -Syy

# Wipes the selected disk and sets up the 4 partitions
sgdisk -og $ai_device
sgdisk -n 1:2048:4095 -c 1:"BIOS Boot Partition" -t 1:ef02 $ai_device
sgdisk -n 2:4096:2101247 -c 2:"EFI System Partition" -t 2:ef00 $ai_device
sgdisk -n 3:2101248:6295551 -c 3:"Linux /boot" -t 3:8300 $ai_device
ENDSECTOR=`sgdisk -E $ai_device`
sgdisk -n 4:6295552:$ENDSECTOR -c 4:"Linux LVM" -t 4:8e00 $ai_device
sgdisk -p $ai_device
sleep 5

# Setup LVM volumes
pvcreate ${ai_device}${ai_partIdent}4
vgcreate vol ${ai_device}${ai_partIdent}4
lvcreate -L 1G vol -n swap
lvcreate -l 100%FREE vol -n root

# Format file systems
mkfs.fat -F32 ${ai_device}${ai_partIdent}2
mkfs.ext4 -F ${ai_device}${ai_partIdent}3
mkfs.ext4 -F /dev/mapper/vol-root
mkswap /dev/mapper/vol-swap
#partprobe

# Mounts the filesystems as needed
mount /dev/mapper/vol-root /mnt
mkdir /mnt/boot
mount ${ai_device}${ai_partIdent}3 /mnt/boot
mkdir /mnt/boot/efi
mount ${ai_device}${ai_partIdent}2 /mnt/boot/efi
swapon /dev/mapper/vol-swap

# Installs the basics and general packages to the chroot
pkgs=`tr '\n' ' ' < /srv/git/d4rks-dotfiles/configs/pkgs_initial.txt`
pacstrap /mnt $pkgs 

# Copies the ranked mirrorlist, generates fstab, copies the git repo downloaded for install into the chroot
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
genfstab -U -p /mnt > /mnt/etc/fstab

# This allows the /run mount to be bound to the chroot, letting grub install correctly
mkdir /mnt/hostrun
mount --bind /run /mnt/hostrun

arch-chroot /mnt /bin/bash <<EOT
# Binds the run mount that was passed through
mount --bind /hostrun/lvm /run/lvm

# Preping timezone, locale and hostname generation
test -f /etc/localtime && rm /etc/localtime
echo $ai_hostname > /etc/hostname
echo "127.0.0.1 $ai_hostname.locald $ai_hostname" >> /etc/hosts
sed -i 's/#en_US/en_US/g' /etc/locale.gen

# Setting up initramfs generation modules and hooks
sed -i "s/MODULES\=\(.*\)/MODULES\=\(ext4\)/" /etc/mkinitcpio.conf
sed -i "/^#/d" /etc/mkinitcpio.conf
sed -i "s/block/block keymap/" /etc/mkinitcpio.conf
sed -i "s/keymap/keymap lvm2/" /etc/mkinitcpio.conf
sed -i "s/lvm2/lvm2 resume/" /etc/mkinitcpio.conf

# Preping grub setup values
sed -i "s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"resume\=\/dev\/mapper\/vol-swap\"/" /etc/default/grub

# Configure pacman
sed -i "s/#Color/Color/" /etc/pacman.conf
sed -i "s/#TotalDownload/TotalDownload/" /etc/pacman.conf
sed -i -e "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

# Generates locale
locale-gen

# Sets the localtime to Detroit
ln -sf /usr/share/zoneinfo/America/Detroit /etc/localtime

pacman-key --populate archlinux
#pacman-key --refresh-keys
pacman-key --recv-keys 7931B6D628C8D3BA
pacman-key --finger 7931B6D628C8D3BA
pacman-key --lsign-key 7931B6D628C8D3BA
echo "[arch4edu]" >> /etc/pacman.conf
echo 'Server = https://arch4edu.keybase.pub/\$arch' >> /etc/pacman.conf
pacman -Syy

cp /etc/sudoers /etc/sudoers.bak
sed -i 's/# \%wheel ALL=(ALL) NOPASSWD: ALL/\%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
useradd -g users -G users,wheel,storage,video -m -s /bin/bash pacmantemp
su - pacmantemp -c 'git clone https://aur.archlinux.org/trizen.git && cd trizen && makepkg -si --skipinteg --noconfirm'
su - pacmantemp -c 'trizen --skipinteg --noconfirm -S vim-plug'
userdel -f -r pacmantemp
test -d /home/pacmantemp && rm -Rf /home/pacmantemp

useradd -g users -G users,wheel,storage,video -m -s /bin/bash $ai_username
printf '%s\n' "$ai_password" "$ai_password" | passwd $ai_username
printf '%s\n' "$ai_password" "$ai_password" | passwd root

# Generates initramfs and installs grub
mkinitcpio -p linux
grub-install --target=i386-pc --recheck $ai_device
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg

# Creates hook folder for pacman
mkdir /etc/pacman.d/hooks

# Sets up ccache and colorgcc
sed -i -e'/BUILDENV/s/color/color ccache/g' /etc/makepkg.conf
sed -i -e'/BUILDENV/s/!ccache//g' /etc/makepkg.conf
sed -i -e'/BUILDENV/s/  / /g' /etc/makepkg.conf
sed -i -e'/CFLAGS/s/"$/ -march=native"/' /etc/makepkg.conf
sed -i -e'/^color-g\+\+:/s/\/usr\/bin/\/usr\/lib\/ccache/g' /etc/colorgcc/colorgccrc
sed -i -e'/^color-gcc:/s/\/usr\/bin/\/usr\/lib\/ccache/g' /etc/colorgcc/colorgccrc
sed -i -e'/^color-c\+\+:/s/\/usr\/bin/\/usr\/lib\/ccache/g' /etc/colorgcc/colorgccrc
sed -i -e'/^color-cc:/s/\/usr\/bin/\/usr\/lib\/ccache/g' /etc/colorgcc/colorgccrc

# Download my dotfiles from github and run the setup script
mkdir /srv/git
chown root.users /srv/git
chmod -R 775 /srv/git
su - $ai_username -c "cd /srv/git && git clone https://github.com/d4rkeagle65/d4rks-dotfiles.git"
su - $ai_username -c 'git config --global user.email "${EMAIL}"'
su - $ai_username -c 'git config --global user.name "${FNAME} ${LNAME}"'
su - $ai_username -c 'sudo bash /srv/git/d4rks-dotfiles/dotfiles-setup.sh ${ai_username}'

# Update vim for the first time (needs internet so it does not error)
su - $ai_username -c 'printf "%s\\n" "" ":PlugUpdate" ":q" ":q" | vim --not-a-term'
#su - $ai_username -c "bash /srv/git/d4rks-dotfiles/scripts/post-install-packages.sh '$ai_password'"
#su - $ai_username -c 'bash /srv/git/d4rks-dotfiles/scripts/post-install-aur-packages.sh'

# Install arch-linux-surface git scripts/firmware/etc
if dmidecode | grep Product | head -1 | grep 'Surface Pro'
then
	su - $ai_username -c "bash /srv/git/d4rks-dotfiles/scripts/arch-linux-surface.sh
fi

sed -i -e '/^auth\s*include\s*system-local-login$/a auth optional pam_gnome_keyring.so' /etc/pam.d/login
sed -i -e '/^session\s*include\s*system-local-login$/a session optional pam_gnome_keyring.so auto_start' /etc/pam.d/login

echo "[device]" > /etc/NetworkManager/conf.d/disable_rand_mac_addr.conf
echo "wifi.scan-rand-mac-address=no" >> /etc/NetworkManager/conf.d/disable_rand_mac_addr.conf

mv /etc/sudoers.bak /etc/sudoers
sed -i 's/# \%wheel ALL=(ALL) ALL/\%wheel ALL=(ALL) ALL/g' /etc/sudoers

test -f /usr/share/xsessions/remmina-gnome.desktop && rm -Rf /usr/share/xsessions/remmina-gnome.desktop

cp /srv/git/d4rks-dotfiles/configs/systemd/00-d4rks.preset /usr/lib/systemd/system-preset/
systemctl preset-all

test -f /root/yubikey-full-disk-encryption && rm -Rf /root/yubikey-full-disk-encryption

# Unmounts the passed lvm, prevents error on exit.
umount /run/lvm
exit
EOT

#if [ -f /dev/mmcblk0p1 ] ; then {
#	mkdir /sd
#	mount /dev/mmcblk0p1 /sd
#	FILE=/sd/${LOGFILENAME}
#	if test -f "$FILE"; then
#		NEW_UUID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
#    		mv $FILE ${FILE}.${NEW_UUID}
#		cp $LOGFILE /sd
#	fi
#	umount /sd
#}

cp $LOGFILE /mnt/home/dhardin

exit

#add dmidecode to initial install files
#move debtap command from post-install-packages to post-install-aur-packages
