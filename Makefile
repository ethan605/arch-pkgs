SHELL = /bin/bash
YAY_INSTALLED = $(command -v yay)
YAY = yay -Syy --asdeps
MAKEPKG = makepkg --syncdeps --install
FONTS = otf-operator-mono-lig ttf-haskplex-nerd

install: base desktop devel sway theme

base: yay qrgpg
	$(YAY) gotop-bin pass-git pass-update zsh-fast-syntax-highlighting
	@cd ethanify-base; $(MAKEPKG)

desktop: yay
	$(YAY) dropbox expressvpn google-chrome ibus-bamboo-git \
		megasync pulseaudio-modules-bt-git webtorrent-cli
	@cd ethanify-desktop; $(MAKEPKG)

devel: yay
	$(YAY) postman-bin slack-desktop
	@cd ethanify-devel; $(MAKEPKG)

sway: yay
	$(YAY) clipman swappy-git swaylock-effects-git
	@cd ethanify-sway; $(MAKEPKG)

theme: yay $(FONTS)
	$(YAY) breeze-snow-cursor-theme otf-stix ttf-indic-otf
	@cd ethanify-theme; $(MAKEPKG)

yay:
ifndef YAY_INSTALLED
	@rm -rf /tmp/yay
	@git clone https://aur.archlinux.org/yay.git /tmp/yay; \
		cd /tmp/yay; $(MAKEPKG) --asdeps
endif

qrgpg:
	@cd utils/qrgpg; $(MAKEPKG) --asdeps

$(FONTS):
	@cd fonts/$@ && $(MAKEPKG) --asdeps

ohmyzsh:
	@curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh; \
		sh -c "/tmp/ohmyzsh.sh"

post_install:
	# @sh -c 'curl -fLo "$(HOME)/.local/share"/nvim/site/autoload/plug.vim --create-dirs \
	   # https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	# @nvim +PlugInstall +qa
	# @mkdir -p $(HOME)/.logs
	# @chezmoi init https://github.com/ethan605/dotfiles
	# @chezmoi apply
	# @chsh -s /usr/bin/zsh

clean:
	@git clean -xd --force
