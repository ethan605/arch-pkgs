SHELL = /bin/bash
YAY = yay -S --asdeps --needed --answerclean All --answerdiff None --answeredit None --answerupgrade None --clean
MAKEPKG = makepkg --cleanbuild --noconfirm --syncdeps --install --needed --clean
META_PACKAGES = base devel desktop theme sway
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
	@sudo mkdir /usr/local/share/zsh; \
		sudo chown $(USER):users /usr/local/share/zsh

nvim:
	@git clone https://github.com/wbthomason/packer.nvim \
		"$(HOME)/.local/share/nvim/site/pack/packer/start/packer.nvim"; \
		nvim +PackerInstall

# Package manager targets
$(META_PACKAGES): 
	@cd ethanify-$@; $(MAKEPKG)

aur:
	@$(YAY) 1password-cli amazon-ecr-credential-helper asdf-vm \
		breeze-snow-cursor-theme browserpass-chrome clipman direnv \
		downgrade dropbox fcitx5-breeze foot google-chrome gotop-bin \
		j4-dmenu-desktop libsixel otf-stix pass-git pass-update slack-wayland \
		swappy-git swaylock-effects-git ttf-indic-otf wev zoxide

flatpak:
	@flatpak install flathub @$(FLATPAK_APPS)

$(FONTS):
	@cd fonts/$@; $(MAKEPKG) --asdeps

clean:
	@git clean -xd --force
