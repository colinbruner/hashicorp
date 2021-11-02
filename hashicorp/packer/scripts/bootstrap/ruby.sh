#!/bin/bash -e

###
# Installs Ruby and Ruby required prerequisites
###

# Guide: https://gorails.com/setup/ubuntu/20.04#ruby-rbenv

###
# Prerequisites
###
# sudo to root

sudo apt-get install -y curl
#curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
#curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
#echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# Required to build Gem native extensions and PostgreSQL
sudo apt-get update
#sudo apt-get install -y git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev nodejs yarn
sudo apt-get install -y git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev
###
# src
###

curl -O http://ftp.ruby-lang.org/pub/ruby/3.0/ruby-3.0.2.tar.gz
tar -xzvf ruby-3.0.2.tar.gz
cd ruby-3.0.2/
./configure
make
sudo make install
ruby -v

sudo gem install bundler

## as Ubuntu
#cd
#git clone https://github.com/rbenv/rbenv.git ~/.rbenv
#git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
## Retroactively enable running rbenv in the rest of the script
#export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$HOME/.rbenv/bin:$PATH"
#eval "$(rbenv init -)"
#
## Persist shell logins
#echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
#echo 'eval "$(rbenv init -)"' >> ~/.bashrc
#echo 'export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc

###
# Ruby
###

#rbenv install 3.0.2
#rbenv global 3.0.2
## Validate Install
#ruby -v

###
# Install Rails
###
sudo gem install rails -N
rails -v

###
# PostgreSQL
###
# PostgreSQL 12 is the default on Ubuntu 20.04
sudo apt-get install -y postgresql libpq-dev
