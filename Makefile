SHELL=/bin/bash

install: ethanify-base

ethanify-base: yay qrgpg
	yay -S --asdeps gotop-bin pass-git pass-update zsh-fast-syntax-highlighting
	cd ethanify-base; \
		makepkg --syncdeps --install

yay:
	rm -rf /tmp/yay
	git clone https://aur.archlinux.org/yay.git /tmp/yay; \
		cd /tmp/yay; \
		makepkg --syncdeps --install --asdeps

qrgpg:
	cd utils/qrgpg; \
		makepkg --syncdeps --install --asdeps

clean:
	git clean -xd --force
