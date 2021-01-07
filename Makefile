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

post_install: zsh autojump nvm rvm chezmoi nvim
	@mkdir -p $(HOME)/.logs

zsh:
	@curl -o- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash; \
		chsh -s /usr/bin/zsh
	@sudo mkdir /usr/local/share/zsh; \
		sudo chown $(USER):users /usr/local/share/zsh

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
	@gpg --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB; \
		curl -sSL https://get.rvm.io | bash -s stable; \
		source $(HOME)/.rvm/scripts/rvm; \
		rvm install 2.4; \
		gem install neovim

chezmoi:
	@chezmoi init https://github.com/ethan605/dotfiles; \
		chezmoi apply

nvim:
	@curl -fLo "$(HOME)/.local/share"/nvim/site/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim; \
		nvim +PlugInstall +qa

clean:
	@git clean -xd --force
