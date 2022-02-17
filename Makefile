SHELL = /bin/bash
YAY = yay -S --asdeps --needed --answerclean All --answerdiff None --answeredit None --answerupgrade None --clean
MAKEPKG = makepkg --cleanbuild --noconfirm --syncdeps --install --needed --clean
META_PACKAGES = base devel sway theme desktop i3
SYSTEMCTL = sudo systemctl enable --now
FLATPAK_APPS = us.zoom.Zoom
FONTS = otf-operator-mono-lig-nerd
UTILS = qrgpg argo-rollouts elixir-ls-bin jless google-chrome-97

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

$(META_PACKAGES): 
	@cd ethanify-$@; $(MAKEPKG)

aur:
	@$(YAY) \
		gotop-bin pass-attr pass-clip pass-extension-tail pass-git pass-update yay zoxide \
		browserpass-chrome dropbox fcitx5-breeze megasync-bin \
		nomachine nordvpn-bin postman-bin slack-desktop spotify webtorrent-cli \
		1password-cli amazon-ecr-credential-helper asdf-vm direnv downgrade \
		grpcurl jdtls kotlin-language-server libffi7 lua-language-server \
		breeze-snow-cursor-theme otf-stix phinger-cursors ttf-indic-otf ttf-whatsapp-emoji \
		clipman foot j4-dmenu-desktop swappy-git swaylock-effects-git tessen waypipe wev

flatpak:
	@flatpak install flathub @$(FLATPAK_APPS)

fonts: $(FONTS)

$(FONTS):
	@cd fonts/$@; $(MAKEPKG) --asdeps

$(UTILS):
	@cd utils/$@; $(MAKEPKG) --asdeps

clean:
	@git clean -xd --force
