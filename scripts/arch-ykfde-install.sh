## https://sandrokeil.github.io/yubikey-full-disk-encryption-secure-boot-uefi/
## https://wiki.archlinux.org/index.php/Rng-tools

# Prompts
read -p "Enter hostname: " sc_hostname
read -s -p "Enter passphrase for luks volumes: " sc_lukspass
echo ""
echo $sc_lukspass > /tmp/templukspass.bin

if ! ping -c 1 "google.com" >/dev/null 2>&1; then
	wifi-menu -o
fi

DISK=/dev/nvme0n1 #TODO: Make a prompt of available disks
EMAIL='dhardin@hardinsolutions.net'
FNAME=David
LNAME=Hardin

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

# Remounts cowspace with 1G of space from the extra packages we need to setup the env
mount -o remount,size=1G /run/archiso/cowspace

# Ranks the mirrors for the fastest 5
yes | pacman -Sy pacman-contrib
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.rank
curl -s "https://www.archlinux.org/mirrorlist/?country=US&protocol=https&use_mirror_status=on" -o /root/mirrorlist.new
sed -e 's/^#Server/Server/' -e '/^#/d' -i /root/mirrorlist.new
rankmirrors -n 5 /root/mirrorlist.new > /etc/pacman.d/mirrorlist.rank
mv /etc/pacman.d/mirrorlist.rank /etc/pacman.d/mirrorlist

# Installes the nessesary packages for Yubikeys use and FDE
yes | pacman -Sy yubikey-manager yubikey-personalization pcsc-tools libu2f-host make json-c cryptsetup git rng-tools yubico-pam
systemctl start {pcscd,rngd}.service

# Wipes the selected disk and sets up the 4 partitions
sgdisk -og $DISK
sgdisk -n 1:2048:4095 -c 1:"BIOS Boot Partition" -t 1:ef02 $DISK
sgdisk -n 2:4096:2101247 -c 2:"EFI System Partition" -t 2:ef00 $DISK
sgdisk -n 3:2101248:6295551 -c 3:"Linux /boot" -t 3:8300 $DISK
ENDSECTOR=`sgdisk -E $DISK`
sgdisk -n 4:6295552:$ENDSECTOR -c 4:"Linux LVM" -t 4:8e00 $DISK
sgdisk -p $DISK
sleep 5
partprobe

# Aquires the yubikey-full-disk-encryption repo and installs it into the live env
git clone https://github.com/agherzan/yubikey-full-disk-encryption.git
cp -f -r yubikey-full-disk-encryption ~/
cd ~/yubikey-full-disk-encryption
make install

# Only if yubikey hasent been setup yet
#ykpersonalize -v -2 -ochal-resp -ochal-hmac -ohmac-lt64 -ochal-btn-trig -oserial-api-visible

# Sets up YKFDE challenge settings prior to creating the encrypted volume
YKFDE_CHALLENGE=$(printf '$sc_lukspass' | sha256sum | awk '{print $1}')
sed -i "s/#YKFDE_CHALLENGE=\"/YKFDE_CHALLENGE=\"$YKFDE_CHALLENGE/g" /etc/ykfde.conf

# Creates and opens the encrypted LVM
printf '%s\n' "$sc_lukspass" | cryptsetup -q luksFormat ${DISK}p4
yk_lukspass=`ykchalresp -2 $YKFDE_CHALLENGE`
printf '%s\n' "$sc_lukspass" "$yk_lukspass" "$yk_lukspass" | cryptsetup luksAddKey ${DISK}p4
printf '%s\n' "$sc_lukspass" "$sc_lukspass" "$yk_lukspass" | ykfde-enroll -d ${DISK}p4 -s 2
cryptsetup open ${DISK}p4 cryptlvm < /tmp/templukspass.bin

# Creates and opens the encrypted boot
printf '%s\n' "$sc_lukspass" | cryptsetup -q luksFormat ${DISK}p3 --type=luks1 --iter-time 100
printf '%s\n' "$sc_lukspass" | cryptsetup open ${DISK}p3 cryptboot

# Setup LVM volumes
pvcreate /dev/mapper/cryptlvm
vgcreate vol /dev/mapper/cryptlvm
lvcreate -L 1G vol -n swap
lvcreate -l 100%FREE vol -n root

# Format file systems
mkfs.fat -F32 ${DISK}p2
mkfs.ext4 -F /dev/mapper/cryptboot
mkfs.ext4 -F /dev/mapper/vol-root
mkswap /dev/mapper/vol-swap
partprobe

# Mounts the filesystems as needed
mount /dev/mapper/vol-root /mnt
mkdir /mnt/boot
mount /dev/mapper/cryptboot /mnt/boot
mkdir /mnt/boot/efi
mount ${DISK}p2 /mnt/boot/efi
swapon /dev/mapper/vol-swap

# Creates the keyfile for the encrypted boot. This still requires a passphrase to be
# used on boot, but using a keyfile allows grub to not need to ask for the passphrase
# twice. Although random characters, this is plaintext, but is also stored on the
# encrypted root partition.
dd bs=512 count=4 if=/dev/random of=/mnt/crypto_keyfile.bin iflag=fullblock
chmod 000 /mnt/crypto_keyfile.bin
printf '%s\n' "$sc_lukspass" | cryptsetup luksAddKey ${DISK}p3 /mnt/crypto_keyfile.bin

# Installs the basics and general packages to the chroot
pacstrap /mnt base base-devel pacman-contrib vim tmux sudo yubikey-manager yubikey-personalization pcsc-tools \
              libu2f-host acpid dbus efibootmgr lvm2 iw dialog gptfdisk make json-c cryptsetup grub git wpa_supplicant \
	      binutils fakeroot polkit yubico-pam intel-ucode ccache colorgcc wireless-regdb net-tools ttf-dejavu \
	      linux-firmware linux-headers elinks exfat-utils htop reptyr unp unrar unzip unarj p7zip unace cpio \
	      sharutils cabextract rpmextract lostfiles bash-completion pygmentize rsync acpi lldpd pulseaudio \
	      pulseaudio-bluetooth pulseaudio-alsa highlight

# Copies the ranked mirrorlist, generates fstab, copies the git repo downloaded for install into the chroot
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
genfstab -U -p /mnt > /mnt/etc/fstab
cp -r /root/yubikey-full-disk-encryption/ /mnt/root/

mkdir /root/.yubico
ykpamcfg -2 -v
mkdir /mnt/etc/yubico

# Getting UUIDs for partitions/volumes
rootcryptuuid=`blkid | grep crypto_LUKS | grep -i LVM | sed -e 's/.* UUID\=\"\(.*\)\".*/\1/' | cut -d'"' -f1`
bootuuid=`blkid | grep crypto_LUKS | grep -i boot | sed -e 's/.* UUID\=\"\(.*\)\".*/\1/' | cut -d'"' -f1`
rootuuid=`blkid | grep root | sed -e 's/.* UUID\=\"\(.*\)\".*/\1/' | cut -d'"' -f1`

# Generating boot strings for grub and crypttab
sc_grub_cmdline="cryptdevice=UUID=${rootcryptuuid}:cryptlvm:allow-discards root=UUID=${rootuuid}"
sc_cryptboot="cryptboot   UUID=${bootuuid}  /crypto_keyfile.bin   luksi,discard"
sc_challnum=`ls /root/.yubico | grep challenge | sed 's/.*challenge\-\(.*\)/\1/'`

mv /root/.yubico/challenge\-${sc_challnum} /mnt/etc/yubico/root\-${sc_challnum}
rm -Rf /root/.yubico

# This allows the /run mount to be bound to the chroot, letting grub install correctly
mkdir /mnt/hostrun
mount --bind /run /mnt/hostrun

arch-chroot /mnt /bin/bash <<EOT
# Binds the run mount that was passed through
mkdir /hostrun/lvm
mount --bind /hostrun/lvm /run/lvm

# Installs the git repo for YKFDE
cd /root/yubikey-full-disk-encryption
make install

# Preping timezone, locale and hostname generation
rm /etc/localtime
echo $sc_hostname > /etc/hostname
echo "127.0.0.1 $sc_hostname.locald $sc_hostname" >> /etc/hosts
sed -i 's/#en_US/en_US/g' /etc/locale.gen

# Setting up initramfs generation modules and hooks
sed -i "s/MODULES\=\(.*\)/MODULES\=\(ext4\)/" /etc/mkinitcpio.conf
sed -i "/^#/d" /etc/mkinitcpio.conf
sed -i "s/block/block keymap/" /etc/mkinitcpio.conf
sed -i "s/keymap/keymap lvm2/" /etc/mkinitcpio.conf
sed -i "s/keymap/keymap ykfde/" /etc/mkinitcpio.conf
sed -i "s/lvm2/lvm2 resume/" /etc/mkinitcpio.conf

# Preping grub setup values
sed -i "s/^#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y/" /etc/default/grub
sed -i "s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"$sc_grub_cmdline resume\=\/dev\/mapper\/vol-swap\"/" /etc/default/grub

# Setting up YKFDE values
sed -i "s/#YKFDE_CHALLENGE_SLOT=\"2\"/YKFDE_CHALLENGE_SLOT=\"2\"/" /etc/ykfde.conf
sed -i "s/#YKFDE_DISK_UUID=\"\"/YKFDE_DISK_UUID=\"${rootcryptuuid}\"/" /etc/ykfde.conf
sed -i "s/#YKFDE_LUKS_NAME=\"\"/YKFDE_LUKS_NAME=\"cryptlvm\"/" /etc/ykfde.conf
sed -i "s/#YKFDE_CHALLENGE=\"/YKFDE_CHALLENGE=\"$YKFDE_CHALLENGE/g" /etc/ykfde.conf

# Configure pacman
sed -i "s/#Color/Color/" /etc/pacman.conf
sed -i "s/#TotalDownload/TotalDownload/" /etc/pacman.conf
sed -i -e "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

pacman -Syy

# Establishing cryptboot for grub
echo $sc_cryptboot >> /etc/crypttab

# Generates locale
locale-gen

# Sets the localtime to Detroit
ln -sf /usr/share/zoneinfo/America/Detroit /etc/localtime

pacman-key --populate archlinux
pacman-key --refresh-keys

cp /etc/sudoers /etc/sudoers.bak
sed -i 's/# \%wheel ALL=(ALL) NOPASSWD: ALL/\%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
useradd -g users -G users,wheel,storage,video -m -s /bin/bash pacmantemp
su - pacmantemp -c 'git clone https://aur.archlinux.org/trizen.git && cd trizen && makepkg -si --skipinteg --noconfirm'
su - pacmantemp -c 'trizen --skipinteg --noconfirm -S cryptboot vim-plug'
su - pacmantemp -c 'trizen --skipinteg --noconfirm -S wd719x-firmware'
su - pacmantemp -c 'trizen --skipinteg --noconfirm -S aic94xx-firmware'
userdel -f -r pacmantemp
rm -Rf /home/pacmantemp
mv /etc/sudoers.bak /etc/sudoers
sed -i 's/# \%wheel ALL=(ALL) ALL/\%wheel ALL=(ALL) ALL/g' /etc/sudoers
useradd -g users -G users,wheel,storage,video -m -s /bin/bash dhardin
printf '%s\n' "$sc_lukspass" "$sc_lukspass" | passwd dhardin
printf '%s\n' "$sc_lukspass" "$sc_lukspass" | passwd root

printf '%s\n' "$sc_hostname" | cryptboot-efikeys create
cryptboot-efikeys enroll

chown root.root -R /etc/yubico/
chmod 700 -R /etc/yubico/
cp "/etc/yubico/root-${sc_challnum}" "/etc/yubico/dhardin-${sc_challnum}"
sed -i -e '/^$/a auth	sufficient	pam_yubico\.so	mode=challenge-response chalresp_path=\/etc\/yubico' /etc/pam.d/system-auth
sed -i -e '/^auth\s*include\s*system-local-login$/a auth optional pam_gnome_keyring.so' /etc/pam.d/login
sed -i -e '/^session\s*include\s*system-local-login$/a session optional pam_gnome_keyring.so auto_start' /etc/pam.d/login

# Generates initramfs and installs grub
mkinitcpio -p linux
grub-install --target=i386-pc --recheck $DISK
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg
cryptboot update-grub

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
su - dhardin -c "cd /srv/git && git clone https://github.com/d4rkeagle65/d4rks-dotfiles.git"
su - dhardin -c 'git config --global user.email "$EMAIL"'
su - dhardin -c 'git config --global user.name "${FNAME} ${LNAME}"'
sh - dhardin -c 'sh /srv/git/d4rks-dotfiles/dotfiles-setup.sh dhardin'

# Update vim for the first time (needs internet so it does not error)
su - dhardin -c 'printf "%s\\n" "" ":PlugUpdate" ":q" ":q" | vim --not-a-term'
su - dhardin -c "sh /srv/git/d4rks-dotfiles/scripts/post-install-packages.sh '$sc_lukspass'"
su - dhardin -c 'sh /srv/git/d4rks-dotfiles/scripts/post-install-aur-packages.sh'

su - dhardin -c 'echo "$sc_lukspass" | gnome-keyring-daemon --login'
su - dhardin -c 'echo "$sc_lukspass" | secret-tool store --label="ownCloud" user dhardin:https://owncloud.axxiscom.com/:0 server ownCloud type plaintext'

echo "[device]" > /etc/NetworkManager/conf.d/disable_rand_mac_addr.conf
echo "wifi.scan-rand-mac-address=no" >> /etc/NetworkManager/conf.d/disable_rand_mac_addr.conf

cp /srv/git/d4rks-dotfiles/configs/systemd/00-d4rks.preset /usr/lib/systemd/system-preset/
systemctl preset-all

rm -Rf /root/yubikey-full-disk-encryption

# Unmounts the passed lvm, prevents error on exit.
umount /run/lvm
exit
EOT
