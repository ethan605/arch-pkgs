SHELL = /bin/bash
YAY = yay -S --asdeps --needed --answerclean All --answerdiff None --answeredit None --answerupgrade None --clean
MAKEPKG = makepkg --cleanbuild --noconfirm --syncdeps --install --needed --clean
META_PACKAGES = base devel sway theme desktop i3
SYSTEMCTL = sudo systemctl enable --now
FLATPAK_APPS = us.zoom.Zoom
FONTS = otf-operator-mono-lig-nerd
UTILS = qrgpg argo-rollouts elixir-ls-bin httpie

yay:
	@rm -rf /tmp/yay
	@git clone https://aur.archlinux.org/yay.git /tmp/yay; \
		cd /tmp/yay; $(MAKEPKG) --asdeps

zsh:
	@chsh -s /usr/bin/zsh
	# For zsh's site-functions
	@sudo mkdir -p /usr/local/share/zsh; \
		sudo chown $(USER):users /usr/local/share/zsh; \
		curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh

nvim:
	@git clone https://github.com/wbthomason/packer.nvim \
		"$(HOME)/.local/share/nvim/site/pack/packer/start/packer.nvim"; \
		nvim +PackerInstall

misc:
	@mkdir -p "$(HOME)/.logs"; \
		touch "$(HOME)/.tool-versions"; \
		gpg --recv-keys \
			3FEF9748469ADBE15DA7CA80AC2D62742012EA22 \
			BE2DBCF2B1E3E588AC325AEAA06B49470F8E620A

$(META_PACKAGES): 
	@cd ethanify-$@; $(MAKEPKG)

aur:
	@$(YAY) \
		gotop-bin pass-attr pass-clip pass-extension-tail pass-git pass-update yay zoxide \
		browserpass-chrome dropbox fcitx5-breeze google-chrome megasync-bin \
		nordvpn-bin postman-bin slack-desktop spotify webtorrent-cli \
		1password-cli amazon-ecr-credential-helper asdf-vm direnv downgrade \
		grpcurl jdtls jless kotlin-language-server libffi7 ltex-ls-bin lua-language-server \
		breeze-snow-cursor-theme otf-stix phinger-cursors ttf-indic-otf ttf-whatsapp-emoji \
		clipman j4-dmenu-desktop swappy-git swaylock-effects-git tessen waypipe wev

core:
	@sudo pacman -S --asdeps direnv exa fzf git-delta keychain \
		openssh pass polkit starship zoxide zsh; \
		yay -S --asdeps asdf-vm 

sway-base:
	@sudo pacman -S --asdeps bemenu-wayland firefox foot \
		sway swaybg swayidle waybar wl-clipboard wofi; \
		yay -S --asdeps j4-dmenu-desktop swaylock-effects-git

flatpak:
	@flatpak install flathub @$(FLATPAK_APPS)

fonts: $(FONTS)

$(FONTS):
	@cd fonts/$@; $(MAKEPKG) --asdeps

$(UTILS):
	@cd utils/$@; $(MAKEPKG) --asdeps

clean:
	@git clean -xd --force
