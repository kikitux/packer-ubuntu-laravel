#!/bin/bash

# Use AU mirrors
sudo sed -i \
-e 's/us.archive.ubuntu.com/au.archive.ubuntu.com/' \
-e 's/archive.ubuntu.com/au.archive.ubuntu.com/' \
/etc/apt/sources.list

# Add NodeSource repo
curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash -

# Install packages
export DEBIAN_FRONTEND=noninteractive
unset PACKAGES
PACKAGES="apache2 mariadb-client mariadb-server php5 php5-cli php5-mysql php5-gd php5-curl php5-mcrypt nodejs git"
sudo -E apt-get install -y -q --no-install-recommends ${PACKAGES}

# Setup Apache virtual host
sudo tee /etc/apache2/sites-enabled/000-default.conf >/dev/null <<-EOF
	<Directory /vagrant/app/public>
	    Options Indexes FollowSymLinks
	    AllowOverride All
	    Require all granted
	</Directory>
	<VirtualHost *:80>
	    DocumentRoot /vagrant/app/public
	    ErrorLog \${APACHE_LOG_DIR}/error.log
	    CustomLog \${APACHE_LOG_DIR}/access.log combined
	</VirtualHost>
	EOF

# Install Composer
php -r "readfile('https://getcomposer.org/installer');" | php
sudo mv composer.phar /usr/bin/composer
sudo chown root:root /usr/bin/composer
sudo chmod 755 /usr/bin/composer
composer global require "laravel/installer"
echo export PATH='${PATH}':~/.composer/vendor/bin | tee -a ~/.bash_profile

# Enable mod_rewrite and mcrypt
sudo a2enmod rewrite
sudo php5enmod mcrypt

# Cleanup
sudo apt-get clean

# Delete /etc/udev/rules.d/70-persistent-net.rule if it exists
[ -f /etc/udev/rules.d/70-persistent-net.rule ] && sudo rm -f /etc/udev/rules.d/70-persistent-net.rule || true

# Zero the filesystem to help compression
sync
sudo dd if=/dev/zero of=/EMPTY bs=1M || true
sudo rm -f /EMPTY
sync
sudo echo 3 > /proc/sys/vm/drop_caches
sync
