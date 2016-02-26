#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
PACKAGES=(apache2 mariadb-client mariadb-server php5 php5-cli php5-mysql php5-gd php5-curl nodejs npm git)
sudo -E apt-get update
sudo -E apt-get install -y -q --no-install-recommends "${PACKAGES[@]}"

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

php -r "readfile('https://getcomposer.org/installer');" | php
sudo mv composer.phar /usr/bin/composer
sudo chown root:root /usr/bin/composer
sudo chmod 755 /usr/bin/composer
composer global require "laravel/installer"

echo export PATH='${PATH}':~/.composer/vendor/bin | tee -a ~/.bash_profile

[ -f /etc/udev/rules.d/70-persistent-net.rule ] && sudo rm -f /etc/udev/rules.d/70-persistent-net.rule || true
