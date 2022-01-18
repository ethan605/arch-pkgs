SHELL = /bin/bash
YAY = yay -S --asdeps --needed
MAKEPKG = makepkg --cleanbuild --noconfirm --syncdeps --install --needed --clean
SYSTEMCTL = sudo systemctl enable --now
SERVICES = bluetooth docker libvirtd virtlogd
FLATPAK_APPS = us.zoom.Zoom
FONTS = otf-operator-mono-lig-nerd

pacman: base desktop devel theme sway

flatpak:
	@flatpak install flathub @$(FLATPAK_APPS)

base: qrgpg
	@$(YAY) foot gotop-bin libsixel pass-git pass-update zoxide
	@cd ethanify-$@; $(MAKEPKG)

desktop:
	@$(YAY) browserpass-chrome dropbox google-chrome fcitx5-breeze \
		megasync-bin nomachine spotify webtorrent-cli
	@cd ethanify-$@; $(MAKEPKG)

devel:
	@$(YAY) 1password-cli amazon-ecr-credential-helper asdf-vm direnv downgrade \
		grpcurl jdtls libffi7 lua-language-server postman-bin
	@cd ethanify-$@; $(MAKEPKG)

theme: $(FONTS)
	@$(YAY) breeze-snow-cursor-theme otf-stix ttf-indic-otf
	@cd ethanify-$@; $(MAKEPKG)

sway:
	@$(YAY) clipman j4-dmenu-desktop slack-wayland swappy-git swaylock-effects-git wev
	@cd ethanify-$@; $(MAKEPKG)

qrgpg:
	@cd utils/qrgpg; $(MAKEPKG) --asdeps

yay:
	@rm -rf /tmp/yay
	@git clone https://aur.archlinux.org/yay.git /tmp/yay; \
		cd /tmp/yay; $(MAKEPKG) --asdeps

$(FONTS):
	@cd fonts/$@ && $(MAKEPKG) --asdeps

configure: zsh chezmoi nvim services
	@mkdir -p $(HOME)/.logs

zsh:
	@chsh -s /usr/bin/zsh
	# For zsh's site-functions
	@sudo mkdir /usr/local/share/zsh; \
		sudo chown $(USER):users /usr/local/share/zsh

chezmoi:
	@chezmoi init https://github.com/ethan605/dotfiles; \
		chezmoi apply

nvim:
	@git clone https://github.com/wbthomason/packer.nvim \
		"$(HOME)/.local/share/nvim/site/pack/packer/start/packer.nvim"; \
		nvim +PackerInstall

services:
	$(foreach service, $(SERVICES), $(SYSTEMCTL) $(service);)

clean:
	@git clean -xd --force
