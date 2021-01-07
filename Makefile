SHELL = /bin/bash
YAY = yay -S --asdeps --answerclean All --answerdiff None --answeredit None --answerupgrade None --clean
MAKEPKG = makepkg --cleanbuild --noconfirm --syncdeps --install --clean
META_PACKAGES = kernel base desktop devel sway theme
FONTS = otf-operator-mono-lig ttf-haskplex-nerd

install: $(META_PACKAGES)

kernel:
	@cd ethanify-$@; $(MAKEPKG)

base: qrgpg
	$(YAY) gotop-bin pass-git pass-update zsh-fast-syntax-highlighting
	@cd ethanify-$@; $(MAKEPKG)

desktop:
	$(YAY) dropbox expressvpn google-chrome ibus-bamboo-git \
		megasync pulseaudio-modules-bt-git webtorrent-cli
	@cd ethanify-$@; $(MAKEPKG)

devel:
	$(YAY) postman-bin slack-desktop
	@cd ethanify-$@; $(MAKEPKG)

sway:
	$(YAY) clipman swappy-git swaylock-effects-git
	@cd ethanify-$@; $(MAKEPKG)

theme: $(FONTS)
	$(YAY) breeze-snow-cursor-theme otf-stix ttf-indic-otf
	@cd ethanify-$@; $(MAKEPKG)

yay:
	@rm -rf /tmp/yay
	@git clone https://aur.archlinux.org/yay.git /tmp/yay; \
		cd /tmp/yay; $(MAKEPKG) --asdeps

qrgpg:
	@cd utils/qrgpg; $(MAKEPKG) --asdeps

$(FONTS):
	@cd fonts/$@ && $(MAKEPKG) --asdeps

post_install: autojump nvm rvm nvim chezmoi zsh
	@mkdir -p $(HOME)/.logs

autojump:
	@git clone https://github.com/wting/autojump.git /tmp/autojump; \
		cd /tmp/autojump; \
		./install.py

nvm:
	@curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash; \
		source $(HOME)/.nvm/nvm.sh; \
		nvm install v14; \
		npm install --global pure-prompt neovim

rvm:

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

clean:
	@git clean -xd --force
