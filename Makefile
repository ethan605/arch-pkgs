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

post_install: nvm nvim chezmoi zsh autojump rvm
	@mkdir -p $(HOME)/.logs

nvm:
	@curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash; \
		source $(HOME)/.nvm/nvm.sh; \
		nvm install v14; \
		npm install --global pure-prompt neovim

nvim:
	@curl -fLo "$(HOME)/.local/share"/nvim/site/autoload/plug.vim --create-dirs \
	   https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim; \
	   nvim +PlugInstall +qa

chezmoi:
	@chezmoi init https://github.com/ethan605/dotfiles; \
		chezmoi apply

zsh:
	@curl -o- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash; \
		chsh -s /usr/bin/zsh

autojump:

rvm:

clean:
	@git clean -xd --force
