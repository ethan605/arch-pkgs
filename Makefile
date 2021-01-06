SHELL=/bin/bash
YAY=$(command -v yay)
MAKEPKG=makepkg --syncdeps --install

install: ethanify-base ethanify-desktop ethanify-devel ethanify-theme

ethanify-base: yay qrgpg
	yay -S --asdeps gotop-bin pass-git pass-update zsh-fast-syntax-highlighting
	cd ethanify-base; $(MAKEPKG)

ethanify-desktop: yay
	yay -S --asdeps dropbox expressvpn google-chrome ibus-bamboo-git \
		megasync pulseaudio-modules-bt-git webtorrent-cli
	cd ethanify-desktop; $(MAKEPKG)

ethanify-devel: yay
	yay -S --asdeps postman-bin slack-desktop
	cd ethanify-devel; $(MAKEPKG)

ethanify-theme: yay fonts
	yay -S --asdeps breeze-snow-cursor-theme otf-stix ttf-indic-otf
	cd ethanify-theme; $(MAKEPKG)

yay:
ifndef YAY
	rm -rf /tmp/yay
	git clone https://aur.archlinux.org/yay.git /tmp/yay; \
		cd /tmp/yay; $(MAKEPKG) --asdeps
endif

qrgpg:
	cd utils/qrgpg; $(MAKEPKG) --asdeps

fonts:
	cd fonts/otf-operator-mono-lig && $(MAKEPKG) --asdeps
	cd fonts/ttf-haskplex-nerd; $(MAKEPKG) --asdeps

clean:
	git clean -xd --force
