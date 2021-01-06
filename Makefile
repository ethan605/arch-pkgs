SHELL=/bin/bash
YAY=$(command -v yay)

install: ethanify-base ethanify-devel

ethanify-base: yay qrgpg
	yay -S --asdeps gotop-bin pass-git pass-update zsh-fast-syntax-highlighting
	cd ethanify-base; \
		makepkg --syncdeps --install

ethanify-devel: yay
	yay -S --asdeps postman-bin slack-desktop
	cd ethanify-devel; \
		makepkg --syncdeps --install

yay:
ifndef YAY
	rm -rf /tmp/yay
	git clone https://aur.archlinux.org/yay.git /tmp/yay; \
		cd /tmp/yay; \
		makepkg --syncdeps --install --asdeps
endif

qrgpg:
	cd utils/qrgpg; \
		makepkg --syncdeps --install --asdeps

clean:
	git clean -xd --force
