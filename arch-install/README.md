# Arch Linux installation guide - Jan 2022

* [0. Preparation](#0-preparation)
  - [Connect to internet](#connect-to-internet)
    - [Ethernet](#ethernet)
    - [Wifi](#wifi)
  - [Console font](#console-font)
  - [Update the system clock](#update-the-system-clock)
* [1. Partition disk & setup LUKS](#1-partition-disk--setup-luks)
  - [Partition the disk](#partition-the-disk)
  - [Setup LVM on LUKS](#setup-lvm-on-luks)
  - [Preparing logical volumes](#preparing-logical-volumes)
  - [Format logical volumes and mount](#format-logical-volumes-and-mount)
  - [Format and mount EFI partition](#format-and-mount-efi-partition)
* [2. Installation](#2-installation)
  - [Bootstrap packages](#bootstrap-packages)
  - [Generate and update `fstab`](#generate-and-update-fstab)
  - [Change root](#change-root)
  - [Configure date time & locale](#configure-date-time-%26-locale)
  - [Configure `hostname`](#configure-hostname)
  - [`initramfs`](#initramfs)
    - [Add `encrypt` and `lvm2` to hooks](#add-encrypt-and-lvm2-to-hooks)
    - [Create `initramfs` image](#create-initramfs-image)
  - [`systemd-boot`](#systemd-boot)
  - [Install & enable NetworkManager](#install-%26-enable-networkmanager)
  - [Set console font](#set-console-font)
  - [Set `root` password](#set-root-password)
  - [Reboot](#reboot)
* [3. Post installation](#3-post-installation)
  - [Secure boot](#secure-boot)
    - [Sign in as `root` and install related tools](#sign-in-as-root-and-install-related-tools)
    - [Generate new keys](#generate-new-keys)
    - [Sign keys](#sign-keys)
    - [Setup `pacman` hooks](#setup-pacman-hooks)
    - [Enrolling keys in firmware](#enrolling-keys-in-firmware)
    - [Notes for Intel NUCs](#notes-for-intel-nucs)
    - [Notes for Lenovo Thinkpad X1 Carbon G9](#notes-for-lenovo-thinkpad-x1-carbon-g9)
  - [Configure users](#configure-users)
    - [Configure `sudo`](#configure-sudo)
    - [Add new user](#add-new-user)
    - [Configure `fprintd` (if applicable)](#configure-fprintd-if-applicable)
  - [Gnome Keyring](#gnome-keyring)
  - [GPG key](#gpg-key)
  - [`chezmoi`, SSH key and `pass`](#chezmoi%2C-ssh-key-%26-pass)
  - [`sway` and base packages](#sway-%26-base-packages)
  - [Enable services](#enable-services)
  - [Full packages](#full-packages)
  - [Screen sharing](#screen-sharing)
  - [NordVPN](#nordvpn)
* [4. Troubleshooting](#4-troubleshooting)

## 0. Preparation

### Connect to internet

#### Ethernet

Nothing to do

#### Wifi

Follow the [offical instructions](https://wiki.archlinux.org/index.php/Iwd#Connect_to_a_network) to connect with `iwd`

```shell
$ ping archlinux.org
```

### [Console font](https://wiki.archlinux.org/title/Linux_console#Fonts)

```shell
$ setfont ter-v22n  # or ter-v32n on high-res screens
```

For the comprehensive list of available fonts:

```shell
$ ls /usr/share/kbd/consolefonts
```

### [Update the system clock](https://wiki.archlinux.org/index.php/installation_guide#Update_the_system_clock)

```shell
$ timedatectl set-ntp true
```

## 1. Partition disk & setup LUKS

### Partition the disk

```shell
$ lsblk
$ DISK=/dev/<disk name>

$ sgdisk --clear \
    --new=1:0:+550MiB --typecode=1:ef00 --change-name=1:EFI \
    --new=2:0:0       --typecode=2:8309 --change-name=2:cryptlvm \
    $DISK
```

Then `gdisk`:

```shell
$ gdisk -l $DISK
```

should print something like this:

```shell
GPT fdisk (gdisk) version 1.0.8

Partition table scan:
  MBR: protective
  BSD: not present
  APM: not present
  GPT: present

...

Number  Start (sector)    End (sector)  Size       Code  Name
   1            2048         1128447   550.0 MiB   EF00  EFI
   2         1128448             ...   ... GiB     8309  cryptlvm
```

### Setup [LVM on LUKS](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LVM_on_LUKS)

```shell
$ cryptsetup luksFormat /dev/disk/by-partlabel/cryptlvm
# type "YES" then passphrase and verify passphrase

$ cryptsetup open /dev/disk/by-partlabel/cryptlvm cryptlvm
# type passphrase to open

$ lsblk
# "cryptlvm" mapper will be revealed under the last partition in $DISK
```

### Preparing logical volumes

Use 8GB for `swap`, 64GB (or more) for `/root` and
[a dedicated `/home` partition](https://askubuntu.com/questions/142695/what-are-the-pros-and-cons-of-having-a-separate-home-partition/142704#142704)

```shell
$ pvcreate /dev/mapper/cryptlvm
$ vgcreate vg /dev/mapper/cryptlvm

$ lvcreate -L 8G vg -n swap
$ lvcreate -L 64G vg -n root
$ lvcreate -l 100%FREE vg -n home

$ lsblk
# "vg-swap", "vg-root" and "vg-home" logical volumes revealed under "cryptlvm"
```

### Format logical volumes and mount

```shell
$ mkswap /dev/vg/swap
$ swapon /dev/vg/swap

$ mkfs.ext4 /dev/vg/root
$ mkfs.ext4 /dev/vg/home

$ mount /dev/vg/root /mnt
$ mkdir /mnt/home
$ mount /dev/vg/home /mnt/home

$ lsblk
# "[SWAP]", "/mnt" and "/mnt/home" displayed in "MOUNTPOINTS" column
```

### Format and mount EFI partition

```shell
$ mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI
$ mkdir /mnt/boot
$ mount /dev/disk/by-partlabel/EFI /mnt/boot

$ lsblk
# "/mnt/boot" displayed in "MOUNTPOINTS" for the 1st partition
```

## 2. Installation

### Bootstrap packages

```shell
$ pacstrap /mnt base linux linux-firmware intel-ucode lvm2 neovim
```

### Generate and update `fstab`

```shell
$ genfstab -U /mnt >> /mnt/etc/fstab
```

Change `relatime` to `noatime` for `root` and `home` volumes

```shell
# /mnt/etc/fstab
# /dev/mapper/vg-root
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   /       ext4    rw,noatime    0 1

# /dev/mapper/vg-home
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   /home   ext4    rw,noatime    0 2
```

### Change root

```shell
$ arch-chroot /mnt
```

### Configure date time & locale

```shell
$ ln -sf /usr/share/zoneinfo/GB /etc/localtime
$ hwclock --systohc
$ echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen
$ locale-gen
$ echo "LANG=en_GB.UTF-8" > /etc/locale.conf
```

### Configure `hostname`

```shell
$ echo "arch" > /etc/hostname
$ echo "127.0.0.1 localhost" >> /etc/hosts
$ echo "::1 localhost" >> /etc/hosts
$ echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts
```

### `initramfs`

#### Add `encrypt` and `lvm2` to HOOKS

```shell
# /etc/mkinitcpio.conf
HOOKS=(base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck)
```

#### Create `initramfs` image

```shell
$ mkinitcpio -p linux
$ ls -lah /boot
# should contain "initramfs-linux-fallback.img", "initramfs-linux.img", "intel-ucode.img" and "vmlinuz-linux"
```

### `systemd-boot`

Install boot loader:

```shell
$ bootctl --path=/boot install
```

Add config to `/boot/loader/loader.conf`:

```shell
default       arch
timeout	      5
editor	      0
console-mode  max
```

Set `editor 0` to ensure the configuration can't be changed on boot

Add boot entries:

```shell
# /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options cryptdevice=UUID={UUID}:cryptlvm root=/dev/vg/root quiet rw
```

```shell
# /boot/loader/entries/arch-fallback.conf
title Arch Linux (fallback)
linux /vmlinuz-linux
initrc /intel-ucode.img
initrd /initramfs-linux-fallback.img
options cryptdevice=UUID={UUID}:cryptlvm root=/dev/vg/root quiet rw
```

Use `:read ! blkid /dev/disk/by-partlabel/cryptlvm` inside `nvim` to retrieve `cryptlvm` partition UUID

### Install & enable [NetworkManager](https://wiki.archlinux.org/index.php/NetworkManager)

```shell
$ pacman -S --asdeps networkmanager
$ systemctl enable NetworkManager.service
```

### Set console font

```shell
$ pacman -S --asdeps terminus-font
$ echo "FONT=ter-v22n" > /etc/vconsole.conf
$ echo "FONT_MAP=8859-2" >> /etc/vconsole.conf
```

### Set `root` password

```shell
$ passwd
```

### Reboot

```shell
$ exit
$ reboot
```

## 3. [Post installation](https://wiki.archlinux.org/title/General_recommendations)

### Secure boot

#### Sign in as `root` and install related tools

```shell
$ pacman -S --asdeps git efitools sbsigntools
```

#### Generate new keys

```shell
$ cd /root
$ git clone https://github.com/ethan605/arch-pkgs.git
$ cd arch-pkgs/arch-install
$ chmod u+x sbkeys.sh
$ ./sbkeys.sh

# Backup keys
$ mkdir -p /root/sbkeys
$ mv GUID.txt db.* KEK.* PK.* /root/sbkeys
```

#### Sign keys

```shell
$ cd /boot
$ sbsign --key /root/sbkeys/db.key --cert /root/sbkeys/db.crt --output vmlinuz-linux vmlinuz-linux
$ sbsign --key /root/sbkeys/db.key --cert /root/sbkeys/db.crt --output EFI/BOOT/BOOTX64.EFI EFI/BOOT/BOOTX64.EFI
```

#### Setup `pacman` hooks

```shell
$ cd arch-pkgs/arch-install
$ mkdir -p /etc/pacman.d/hooks
$ cp *.hook /etc/pacman.d/hooks
```

#### Enrolling keys in firmware

Reboot in UEFI and put the firmware to "Setup" mode:

```shell
$ systemctl reboot --firmware
```

Use [`sbkeysync`](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#Using_sbkeysync) to install keys:

```shell
$ mkdir -p /etc/secureboot/keys/{db,KEK,PK}

# Copy .auth files to the new folders
$ cp /roots/sbkeys/db.auth /etc/secureboot/keys/db/
$ cp /roots/sbkeys/KEK.auth /etc/secureboot/keys/KEK/
$ cp /roots/sbkeys/PK.auth /etc/secureboot/keys/PK/

# Verify
$ ls /etc/secureboot/keys/*

# Verify with dry-run
$ sbkeysync --pk --dry-run --verbose

# Enroll keys - db & KEK first
$ sbkeysync --verbose

# Enroll keys - PK last
$ sbkeysync --verbose --pk
```

#### Notes for Intel NUCs

* Within **Intel Visual BIOS**, there are no options to manually enroll the keys,
  hence the option of [using firmware setup utility](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#Using_firmware_setup_utility) is not feasible.
* After Secure Boot is successfully set, boot options like "F2 to Enter Setup" and
  "F10 to Enter Boot Menu" might disappear but pressing those keys should still work.

#### Notes for Lenovo Thinkpad X1 Carbon G9

* Enrolling db & KEK with `sbkeysync --verbose` might end up with `Operation not permitted` error. Run:

```shell
$ chattr -i /sys/firmware/efi/efivars/{db,KEK}*
```

and re-enrol.

* Enrolling PK with `sbkeysync --pk --verbose` might end up with `Permission denied` error. Use instead:

```shell
$ efi-updatevar -f /etc/secureboot/keys/PK/PK.auth PK
```

Reboot to BIOS to check the firmware being back to "User" mode,
then reboot to Arch Linux to verify
[secure boot status](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#After_booting_the_OS).

### Configure users

#### Configure `sudo`

Install `base-devel` (with `sudo` and other packages for development)

```shell
$ pacman -S --asdeps base-devel
```

Allow members of group `wheel` to execute any command:

```shell
$ EDITOR=nvim visudo
```

then uncomment the line with content: `%wheel ALL=(ALL) ALL`

#### Add new user

```shell
$ useradd -m -G wheel ethanify
$ passwd ethanify
```

#### Configure [`fprintd`](https://wiki.archlinux.org/title/Fprint) (if applicable)

```shell
$ sudo fprintd-enroll ethanify
# Scan right index finger 5 times

$ fprintd-verify
# Verify right index finger

$ sudo fprintd-enroll ethanify --finger=left-index-finger
# Scan left index finger 5 times

$ fprintd-verify
# Verify left index finger
```

### Gnome Keyring

Add optional entries to `/etc/pam.d/login`

```shell
# /etc/pam.d/login
# ... other auth entries
auth       optional     pam_gnome_keyring.so
# ... other session entries
session    optional     pam_gnome_keyring.so auto_start
# ... other entries
```

### GPG key

Login to `ethanify` and clone `arch-pkgs`:

```shell
$ git clone https://github.com/ethan605/arch-pkgs
$ cd arch-pkgs
$ make qrgpg

$ cd <private key path>
$ qrgpg decode -o private.asc *.png
# properly decrypt private.asc

$ gpg --import private.asc
$ gpg --edit-key thanhnx.605@gmail.com
# follow https://www.gnupg.org/gph/en/manual/x334.html
```

### `chezmoi`, SSH key & `pass`

```shell
$ sudo pacman -S --asdeps chezmoi
$ chezmoi init https://github.com/ethan605/dotfiles.git
# input prompt configs
$ chezmoi apply ~/.ssh

$ eval $(ssh-agent)
$ ssh-add ~/.ssh/id_ed25519
# enter passphrase from dotfiles/ssh in pass

$ git clone git@github.com:ethan605/<password-store-repo>.git ~/.password-store

$ chezmoi cd
$ git remote set-url origin git@github.com:ethan605/dotfiles.git
$ git remote set-url --push origin git@github.com:ethan605/dotfiles.git
$ chezmoi apply
```

### `sway` & base packages

```shell
$ cd arch-pkgs

# For AUR packages
$ make yay

# Minimal packages to boot into Sway
$ make core
$ make sway-base
$ make nvim
$ make zsh
$ make misc

# logout and login again to boot into sway
```

### Full packages

Add GPG keys:

```shell
$ gpg --recv-keys \
  3FEF9748469ADBE15DA7CA80AC2D62742012EA22 \
  BE2DBCF2B1E3E588AC325AEAA06B49470F8E620A
```

```shell
$ cd arch-pkgs

$ make fonts

$ make aur-base
$ make base

$ make aur-theme
$ make theme

$ make aur-devel
$ make devel

$ make aur-desktop
$ make desktop

$ make aur-sway
$ make sway

# Other metapackages if necessary

$ make flatpak
```

Add metapackages to ignore list of `pacman.conf`:

```shell
# /etc/pacman.conf
IgnorePkg   = ethanify-base ethanify-desktop ethanify-devel ethanify-sway ethanify-theme ... otf-operator-mono-lig-nerd
```

### Enable services

```shell
$ systemctl start bluetooth docker
$ systemctl --user start mpd syncthing
$ sudo gpasswd -a $USER docker
```

### Screen sharing

(mostly following [this guide](https://soyuka.me/make-screen-sharing-wayland-sway-work/))

Check for required service to be running:

```shell
$ systemctl --user status pipewire xdg-desktop-portal xdg-desktop-portal-wlr
```

Open `google-chrome` & enable `enable-webrtc-pipewire-capturer` in `chrome://flags`

### [NordVPN](https://wiki.archlinux.org/title/NordVPN)

```shell
$ device=$(/usr/bin/ls /sys/class/ieee80211/*/device/net)

# Disable IPv6
$ nmcli dev mod $device ipv6.method disabled

# Disable auto DNS & add NordVPN DNSes
$ nmcli dev mod $device ipv4.ignore-auto-dns yes
$ nmcli dev mod $device ipv4.dns "103.86.96.100 103.86.99.100"

$ groupadd -r nordvpn
$ gpasswd -a $USER nordvpn
$ systemctl enable nordvpnd
# Logout & login again

$ nordvpn login
$ nordvpn set technology nordlynx
$ nordvpn set notify enable
$ nordvpn whitelist add subnet 192.168.1.0/24
```

## 4. Troubleshooting

In case of system malfunctions (eg. boot corrupted, network not working),
boot the system with the LiveCD, then manually decrypt & mount the partitions:

```shell
$ cryptsetup open /dev/disk/by-partlabel/cryptlvm cryptlvm
$ swapon /dev/vg/swap
$ mount /dev/vg/root /mnt
$ mount /dev/vg/home /mnt/home
$ mount /dev/disk/by-partlabel/EFI /mnt/boot

$ lsblk
# "/mnt/boot", "[SWAP]", "/mnt" and "/mnt/home" should display in "MOUNTPOINTS"

$ arch-chroot /mnt
```
