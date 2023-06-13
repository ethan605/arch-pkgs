SHELL = /bin/bash
YAY = yay -S --asdeps --needed --answerclean All --answerdiff None --answeredit None --answerupgrade None
MAKEPKG = makepkg --cleanbuild --noconfirm --syncdeps --install --needed --clean
META_PACKAGES = base devel sway theme desktop thinkpad personal work virt
SYSTEMCTL = sudo systemctl enable --now
FONTS = otf-operator-mono-nerd otf-operator-mono-ssm-nerd ttf-cabin
UTILS = qrgpg xkpasswd argo-rollouts elixir-ls-bin

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
		touch "$(HOME)/.logs/swayidle.log"; \
		touch "$(HOME)/.tool-versions"; \
		gpg --recv-keys \
			3FEF9748469ADBE15DA7CA80AC2D62742012EA22 \
			BE2DBCF2B1E3E588AC325AEAA06B49470F8E620A

$(META_PACKAGES): 
	@cd ethanify-$@; $(MAKEPKG)

aur-base:
	@$(YAY) gotop-bin pass-attr pass-clip pass-extension-tail pass-update pipes.sh

aur-desktop:
	@$(YAY) browserpass-chrome fcitx5-breeze google-chrome postman-bin webtorrent-cli

aur-devel:
	@$(YAY) asdf-vm direnv downgrade grpcurl jdtls kotlin-language-server \
		libffi7 ltex-ls-bin lua-language-server perl-image-exiftool

aur-theme:
	@$(YAY) breeze-snow-cursor-theme otf-stix phinger-cursors ttf-indic-otf ttf-whatsapp-emoji

aur-personal:
	@$(YAY) dropbox megasync-bin nordvpn-bin

aur-sway:
	@$(YAY) clipman j4-dmenu-desktop swappy-git tessen waypipe wev

aur-work:
	@$(YAY) 1password-cli amazon-ecr-credential-helper debtap endpoint-verification-chrome fleet-osquery mdatp-bin slack-desktop zoom

core:
	@sudo pacman -S --asdeps direnv exa fzf git-delta keychain \
		openssh pass polkit starship zoxide zsh; \
		yay -S --asdeps asdf-vm 

sway-base:
	@sudo pacman -S --asdeps bemenu-wayland firefox foot \
		sway swaybg swayidle waybar wl-clipboard wofi; \
		yay -S --asdeps j4-dmenu-desktop swaylock-effects-git

fonts: $(FONTS)

$(FONTS):
	@cd fonts/$@; $(MAKEPKG) --asdeps

$(UTILS):
	@cd utils/$@; $(MAKEPKG) --asdeps

clean:
	@git clean -xd --force
