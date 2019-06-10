umount -R /mnt
swapoff /dev/mapper/vol-swap
printf '%s\n' "y" "y" | lvremove vol
vgremove vol
pvremove /dev/mapper/cryptlvm
cryptsetup close /dev/mapper/cryptboot
cryptsetup close /dev/mapper/cryptlvm
