# Arch Linux installation guide - Jan 2022

## 0. Preparation

### Connect to internet

#### Ethernet

Nothing to do

#### Wifi

Follow the [offical instructions](https://wiki.archlinux.org/index.php/Iwd#Connect_to_a_network) to connect with `iwd`

```shell
$ ping archlinux.org
```

#### Console font

```shell
$ setfont ter-v22n
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
    --new=1:0:+1MiB   --typecode=1:ef02 --change-name=1:BIOS \
    --new=2:0:+550MiB --typecode=2:ef00 --change-name=2:EFI \
    --new=3:0:0       --typecode=3:8309 --change-name=3:cryptlvm \
    $DISK
```

Then `gdisk`:

```shell
$ gdisk -l $DISK
```

should print something like this:

| Number | Start (sector) | End (sector) | Size               | Code | Name     |
| -----: | -------------: | -----------: | ------------------ | ---- | -------- |
| 1      | 2048           | 4095         | 1024.0 KiB         | EF02 | BIOS     |
| 2      | 4096           | 1130495      | 550.0 MiB          | EF00 | EFI      |
| 3      | 1130496        | ...          | (rest of the disk) | 8309 | cryptlvm |

### Setup [LUKS on LVM](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_LVM)

```shell
$ cryptsetup luksFormat /dev/disk/by-partlabel/cryptlvm
# type "YES" then passphrase and verify passphrase

$ cryptsetup open /dev/disk/by-partlabel/cryptlvm cryptlvm
# type passphrase to open

$ lsblk
# "cryptlvm" mapper will be revealed under the 3rd partition in $DISK
```

### Preparing logical volumes

```shell
$ pvcreate /dev/mapper/cryptlvm
$ vgcreate vg /dev/mapper/cryptlvm

$ lvcreate -L 8G vg -n swap
$ lvcreate -L 32G vg -n root
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
# "/mnt/boot" displayed in "MOUNTPOINTS" for the 2nd partition
```

## 2. Installation

### Bootstrap packages

```shell
$ pacstrap /mnt base linux linux-firmware intel-ucode lvm2 neovim
```

### Generate and update fstab

```shell
$ genfstab -U /mnt >> /mnt/etc/fstab
```

Change `relatime` to `noatime` for `root` and `home` volumes

```shell
# /mnt/etc/fstab
# /dev/mapper/vg-root
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx / ext4 rw,noatime 0 1

# /dev/mapper/vg-home
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx / ext4 rw,noatime 0 1
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

### Configure hostname

```shell
$ echo "arch" > /etc/hostname
$ echo "127.0.0.1 localhost" >> /etc/hosts
$ echo "::1 localhost" >> /etc/hosts
$ echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts
```

### Initramfs

#### Add `encrypt` and `lvm2` to HOOKS

```shell
# /etc/mkinitcpio.conf
HOOKS=(base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck)
```

#### Create initramfs image:

```shell
$ mkinitcpio -p linux
$ ls -lah /boot
# should contain "initramfs-linux-fallback.img", "initramfs-linux.img", "intel-ucode.img" and "vmlinuz-linux"
```

### Systemd-boot

Install boot loader:

```shell
$ bootctl --path=/boot install
```

Add config to `/boot/loader/loader.conf`:

```shell
default arch
timeout 5
editor  0
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

### Set root password

```shell
$ passwd
```

### Reboot

```shell
$ exit
$ reboot
```

## 3. [Post installation](https://wiki.archlinux.org/index.php/installation_guide#Configure_the_system)

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

# Prepare keys to sign and enroll
$ cp *.auth *.cer *.esl db.key db.crt /boot
```

#### Sign keys

```shell
$ cd /boot
$ sbsign --key db.key --cert db.crt --output vmlinuz-linux vmlinuz-linux
$ sbsign --key db.key --cert db.crt --output EFI/BOOT/BOOTX64.EFI EFI/BOOT/BOOTX64.EFI
```

#### Setup `pacman` hooks

```shell
$ cd arch-pkgs/arch-install
$ mkdir -p /etc/pacman.d/hooks
$ cp *.hook /etc/pacman.d/hooks
```

#### Enrolling keys in firmware

Reboot in UEFI and assign the keys using
[firmware setup utility](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#Using_firmware_setup_utility):

```shell
$ systemctl reboot --firmware
```

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

### Chezmoi, SSH key & Pass

```shell
$ sudo pacman -S --asdeps chezmoi
$ chezmoi init https://github.com/ethan605/dotfiles.git
# input prompt configs
$ chezmoi apply ~/.ssh

$ eval $(ssh-agent)
$ ssh-add ~/.ssh/id_ed25519
# enter passphrase

$ git clone git@github.com:ethan605/<password-store-repo>.git ~/.password-store

$ chezmoi cd
$ git remote remove origin
$ git remote add origin git@github.com:ethan605/dotfiles.git
$ chezmoi apply
```

### Sway & base packages

```shell
$ cd arch-pkgs

$ make yay
$ make zsh
$ make nvim

$ pacman -S --asdeps sway waybar firefox
$ yay -S --asdeps foot
# logout and login again to boot into sway
```

### Full packages

```shell
$ cd arch-pkgs

$ make aur
$ make base
$ make devel
$ make sway
$ make theme
$ make desktop
$ make flatpak
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
# "/mnt/efi", "[SWAP]", "/mnt" and "/mnt/home" should display in "MOUNTPOINTS"

$ arch-chroot /mnt
```
