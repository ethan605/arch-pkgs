SHELL = /bin/bash
YAY = yay -S --asdeps --needed --answerclean All --answerdiff None --answeredit None --answerupgrade None --clean
MAKEPKG = makepkg --cleanbuild --noconfirm --syncdeps --install --needed --clean
META_PACKAGES = base devel sway theme desktop
SYSTEMCTL = sudo systemctl enable --now
FLATPAK_APPS = us.zoom.Zoom
FONTS = otf-operator-mono-lig-nerd

# Post-install targets
qrgpg:
	@cd utils/qrgpg; $(MAKEPKG) --asdeps

yay:
	@rm -rf /tmp/yay
	@git clone https://aur.archlinux.org/yay.git /tmp/yay; \
		cd /tmp/yay; $(MAKEPKG) --asdeps

zsh:
	@chsh -s /usr/bin/zsh
	# For zsh's site-functions
	@sudo mkdir -p /usr/local/share/zsh; \
		sudo chown $(USER):users /usr/local/share/zsh

nvim:
	@git clone https://github.com/wbthomason/packer.nvim \
		"$(HOME)/.local/share/nvim/site/pack/packer/start/packer.nvim"; \
		nvim +PackerInstall

# Package manager targets
$(META_PACKAGES): 
	@cd ethanify-$@; $(MAKEPKG)

aur:
	@$(YAY) \
		gotop-bin pass-attr pass-clip pass-extension-tail pass-git pass-update yay zoxide \
		browserpass-chrome dropbox fcitx5-breeze google-chrome megasync-bin \
		nomachine postman-bin slack-desktop spotify webtorrent-cli \
		1password-cli amazon-ecr-credential-helper asdf-vm direnv downgrade \
		grpcurl jdtls kotlin-language-server libffi7 lua-language-server \
		breeze-snow-cursor-theme otf-stix phinger-cursors ttf-indic-otf ttf-whatsapp-emoji \
		clipman foot j4-dmenu-desktop swappy-git swaylock-effects-git wev

flatpak:
	@flatpak install flathub @$(FLATPAK_APPS)

fonts: $(FONTS)

$(FONTS):
	@cd fonts/$@; $(MAKEPKG) --asdeps

clean:
	@git clean -xd --force
