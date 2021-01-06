SHELL=/bin/bash

install: yay base

yay:
	sudo pacman -S --asdeps git
	rm -rf /tmp/yay
	git clone https://aur.archlinux.org/yay.git /tmp/yay; \
		cd /tmp/yay; \
		makepkg --syncdeps --install --asdeps

base: qrgpg

qrgpg:
	cd utils/qrgpg; \
		makepkg --syncdeps --install --asdeps --force

clean:
	git clean -xd --force
