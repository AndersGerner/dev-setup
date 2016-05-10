#!/usr/bin/env bash

# Install command-line tools using Homebrew.

# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Check for Homebrew,
# Install if we don't have it
if test ! $(which brew); then
  echo "Installing homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo "Installing ZSH and its goodies"
brew install zsh zsh-completions zsh-syntax-highlighting
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
chsh -s /usr/local/bin/zsh
echo "ZSH_THEME=pygmalion\n# Use sublimetext for editing config files\nalias zshconfig="subl ~/.zshrc"\nalias envconfig="subl ~/Sites/config/env.sh"\nplugins=(git colored-man colorize github jira vagrant virtualenv pip python brew osx zsh-syntax-highlighting)\n# Add env.sh\n. ~/Sites/config/env.sh" >> ~/.zshrc
mkdir -p ~/Sites/config
cp env.sh ~/Sites/config/env.sh

echo "Setting up DNSMSQ"
brew install dnsmasq
cd $(brew --prefix)
mkdir etc
echo 'address=/.dev/127.0.0.1' > etc/dnsmasq.conf
sudo cp -v $(brew --prefix dnsmasq)/homebrew.mxcl.dnsmasq.plist /Library/LaunchDaemons
sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist
sudo mkdir /etc/resolver
sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/dev'

sudo apachectl restart

echo "TODO: \n Load: libphp5.so \n outcomment <Directory /> \n Load mod_chost_alias \n Include vhosts"

touch ~/Sites/httpd-vhosts.conf
sudo ln -s ~/Sites/httpd-vhosts.conf /etc/apache2/other

echo "<Directory \"/Users/`whoami`/Sites\">
    Options Indexes MultiViews FollowSymLinks
    AllowOverride All
    Order allow,deny
    Allow from all
  </Directory>

  <Virtualhost *:80>
    VirtualDocumentRoot \"/Users/`whoami`/Sites/home/\"
    ServerName home.dev
    UseCanonicalName Off
  </Virtualhost>

  <Virtualhost *:80>
    VirtualDocumentRoot \"/Users/`whoami`/Sites/%1/\"
    ServerName sites.dev
    ServerAlias *.dev
    UseCanonicalName Off
  </Virtualhost>

  <Virtualhost *:80>
    VirtualDocumentRoot \"/Users/`whoami`/Sites/%-7+/\"
    ServerName xip
    ServerAlias *.xip.io
    UseCanonicalName Off
  </Virtualhost>

" > ~/Sites/httpd-vhosts.conf

sudo apachectl restart

mkdir -p ~/Sites/home
git clone https://cph-cloud@bitbucket.org/cph-cloud/home.dev.git ~/Sites/home

sed -i 's/username/`whoami`/g' ~/Sites/home/config.php
sudo mkdir /private/etc/apache2/extra/vhosts
sudo touch /private/etc/apache2/extra/vhosts/empty.conf
