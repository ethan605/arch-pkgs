SHELL = /bin/bash
YAY = yay -S --asdeps --needed --answerclean All --answerdiff None --answeredit None --answerupgrade None --clean
MAKEPKG = makepkg --cleanbuild --noconfirm --syncdeps --install --needed --clean
SYSTEMCTL = sudo systemctl enable --now
SERVICES = bluetooth docker expressvpn libvirtd virtlogd
META_PACKAGES = kernel base desktop devel theme
FONTS = otf-operator-mono-lig ttf-haskplex-nerd

install: $(META_PACKAGES)

configure: zsh autojump nvm rvm chezmoi nvim services
	@mkdir -p $(HOME)/.logs

kernel:
	@cd ethanify-$@; $(MAKEPKG)

base: qrgpg
	@$(YAY) autojump-rs gotop-bin pass-git pass-update zsh-fast-syntax-highlighting
	@cd ethanify-$@; $(MAKEPKG)

desktop:
	@$(YAY) browserpass-chrome dropbox expressvpn google-chrome ibus-bamboo-git \
		megasync-bin webtorrent-cli zoom-system-qt
	@cd ethanify-$@; $(MAKEPKG)

devel:
	@$(YAY) 1password-cli asdf-vm downgrade postman-bin slack-desktop
	@cd ethanify-$@; $(MAKEPKG)

theme: $(FONTS)
	@$(YAY) breeze-snow-cursor-theme otf-stix ttf-indic-otf
	@cd ethanify-$@; $(MAKEPKG)

sway:
	@$(YAY) clipman swappy-git swaylock-effects-git
	@cd ethanify-$@; $(MAKEPKG)

i3:
	@cd ethanify-$@; $(MAKEPKG)

yay:
	@rm -rf /tmp/yay
	@git clone https://aur.archlinux.org/yay.git /tmp/yay; \
		cd /tmp/yay; $(MAKEPKG) --asdeps

qrgpg:
	@cd utils/qrgpg; $(MAKEPKG) --asdeps

$(FONTS):
	@cd fonts/$@ && $(MAKEPKG) --asdeps

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
		nvm install --lts; \
		npm install --global pure-prompt neovim

rvm:
	@gpg --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB; \
		curl -sSL https://get.rvm.io | bash -s stable; \
		source $(HOME)/.rvm/scripts/rvm; \
		rvm install 2.7; \
		gem install neovim

pyenv:
	@pyenv install 3.9.0; \
		pyenv install 2.7.18; \
		pyenv global 3.9.0 2.7.18; \
		pip3 install --upgrade pip; \
		pip3 install neovim-remote; \
		pip2 install --upgrade pip; \
		pip2 install neovim

chezmoi:
	@chezmoi init https://github.com/ethan605/dotfiles; \
		chezmoi apply

nvim:
	@curl -fLo "$(HOME)/.local/share"/nvim/site/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim; \
		nvim +PlugInstall +qa

services:
	$(foreach service, $(SERVICES), $(SYSTEMCTL) $(service);)

clean:
	@git clean -xd --force
