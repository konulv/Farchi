#!/usr/bin/env bash

##  This is the simplest possible Arch Linux install script I think...
HOSTNAME="lil-fellow"
#VIDEO_DRIVER="xf86-video-vmware"
#IN_DEVICE=/dev/sda
# BOOT_DEVICE="${IN_DEVICE}1"
# SWAP_DEVICE="${IN_DEVICE}2"
# ROOT_DEVICE="${IN_DEVICE}3"
IN_DEVICE=/dev/nvme0n1
BOOT_DEVICE="${IN_DEVICE}p1"
SWAP_DEVICE="${IN_DEVICE}p2"
ROOT_DEVICE="${IN_DEVICE}p3"


TIME_ZONE="Europe/London"
LOCALE="en_GB.UTF-8"
KEYBOARD="gb"    # change if you need to

BASE_SYSTEM=( base base-devel linux linux-firmware sof-firmware iwd networkmanager grub efibootmgr nano )
#devel_stuff=( git nodejs npm npm-check-updates ruby )
#printing_stuff=( system-config-printer foomatic-db foomatic-db-engine gutenprint cups cups-pdf cups-filters cups-pk-helper ghostscript gsfonts )
#multimedia_stuff=( brasero sox eog shotwell imagemagick sox cmus mpg123 alsa-utils cheese )


# All purpose error
error(){ echo "Error: $1" && exit 1; }

###############################
###  START SCRIPT HERE
###############################

### Check of reflector is done
clear
echo "Waiting until reflector has finished updating mirrorlist..."
while true; do
    pgrep -x reflector &>/dev/null || break
    echo -n '.'
    sleep 2
done

### Test internet connection
clear
echo "Testing internet connection..."
$(ping -c 3 archlinux.org &>/dev/null) || (echo "Not Connected to Network!!!" && exit 1)
echo "Good!  We're connected!!!" && sleep 3

## Check time and date before installation
timedatectl set-ntp true
echo && echo "Date/Time service Status is . . . "
timedatectl status
sleep 4


####  Could just use cfdisk to partition drive
cfdisk "$IN_DEVICE"    # for non-EFI VM: /boot 512M; / 13G; Swap 2G; Home Remainder

###  NOTE: Drive partitioning is one of those highly customizable areas where your
###        personal preferences and needs will dictate your choices.  Many options
###        exist here.  An MBR disklabel is very old, limited, and may well inspire
###        you to investigate other options, which is a good exercise.  But, MBR is pretty
###        simple and reliable, within its constraints.  Bon voyage!


#####  Format filesystems
mkfs.ext4 "$ROOT_DEVICE"         # /mnt
mkfs.fat -F 32 "$BOOT_DEVICE"    # /mnt/boot/efi
mkswap "$SWAP_DEVICE"            # swap partition

#### Mount filesystems
mount "$ROOT_DEVICE" /mnt
mkdir -p /mnt/boot/efi && mount "$BOOT_DEVICE" /mnt/boot/efi
swapon "$SWAP_DEVICE"


lsblk && echo "Here're your new block devices. (Type any key to continue...)" ; read empty


###  Install base system
clear
echo && echo "Press any key to continue to install BASE SYSTEM..."; read empty
pacstrap /mnt "${BASE_SYSTEM[@]}"
echo && echo "Base system installed.  Press any key to continue..."; read empty

# GENERATE FSTAB
echo "Generating fstab..."
genfstab /mnt > /mnt/etc/fstab
cat /mnt/etc/fstab
echo && echo "Here's your fstab. Type any key to continue..."; read empty

## SET UP TIMEZONE AND LOCALE
clear
echo && echo "setting timezone to $TIME_ZONE..."
arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$TIME_ZONE" /etc/localtime
arch-chroot /mnt hwclock --systohc 
arch-chroot /mnt date
echo && echo "Here's the date info, hit any key to continue..."; read empty

## SET UP LOCALE
clear
echo && echo "setting locale to $LOCALE ..."
arch-chroot /mnt sed -i "s/#$LOCALE/$LOCALE/g" /etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=$LOCALE" > /mnt/etc/locale.conf
export LANG="$LOCALE"
cat /mnt/etc/locale.conf
echo && echo "Here's your /mnt/etc/locale.conf. Type any key to continue."; read empty

## keyboard
echo "KEYMAP=$KEYBOARD" > /mnt/etc/vconsole.conf

## HOSTNAME
clear
echo && echo "Setting hostname..."; sleep 3
echo "$HOSTNAME" > /mnt/etc/hostname

cat /mnt/etc/hostname 
echo && echo "Here are /etc/hostname. Type any key to continue "; read empty

## SET ROOT PASSWD
clear
echo "Setting ROOT password..."
arch-chroot /mnt passwd

## INSTALLING MORE ESSENTIALS
clear
# echo && echo "Enabling dhcpcd, pambase, sshd and NetworkManager services..." && echo
# arch-chroot /mnt pacman -S git openssh networkmanager dhcpcd man-db man-pages pambase
echo && echo "Enabling Systemctl services..." && echo

arch-chroot /mnt systemctl enable iwd.service
echo "[General]" > /mnt/etc/iwd/main.conf
echo "EnableNetworkConfiguration=true" >> /mnt/etc/iwd/main.conf

arch-chroot /mnt systemctl enable NetworkManager
echo && echo "Press any key to continue..."; read empty

## ADD USER ACCT
clear
echo && echo "Adding sudo + user acct..."
sleep 2
arch-chroot /mnt sed -i 's/# %wheel/%wheel/1' /etc/sudoers
echo && echo "Please provide a username: "; read sudo_user
echo && echo "Creating $sudo_user and adding $sudo_user to sudoers..."
arch-chroot /mnt useradd -m -G wheel -s /bin/bash  "$sudo_user"
echo && echo "Password for $sudo_user?"
arch-chroot /mnt passwd "$sudo_user"

## Not installing X in this script...

## INSTALL GRUB
clear
echo "Setting up grub..." && sleep 2

## We're not checking for EFI; We're assuming MBR
arch-chroot /mnt grub-install "$IN_DEVICE"

echo "configuring /boot/grub/grub.cfg..."
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
[[ "$?" -eq 0 ]] && echo "mbr bootloader installed..."

echo "configuring post-intsall script..."

curl https://raw.githubusercontent.com/deepbsd/farchi/master/myownpost.sh -o /mnt/home/konulv/post-instal.sh
arch-chroot /mnt chmod +x /home/konulv/post-instal.sh

echo "Your system is installed.  Type shutdown -h now to shutdown system and remove bootable media, then restart"
read empty
