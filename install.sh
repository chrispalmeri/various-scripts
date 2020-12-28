#!/bin/bash

# be running as root
if [[ $EUID != 0 ]]; then
  echo "This script needs to be run as root." >&2
  exit 1
fi

build=/home/www-data/app
serve=/srv/app

if [[ $1 ]]; then
  echo "vagrant"
  build=/vagrant
  serve=/vagrant
fi


# Make a log directory
mkdir -p $build/log

# Update and install software
apt-get update
apt-get install -y git apache2 sqlite3 php libapache2-mod-php php-curl php-sqlite3
# ufw? is that any problem locally?


# need to stop apache while modifying the user
systemctl stop apache2

# give www-data a proper home directory
# that's the user php will run commands as
# want it to have a place to put stuff
# where it has permission to `git pull` later
mkdir -p /home/www-data
chown www-data:www-data /home/www-data
usermod -d /home/www-data www-data

# clone repo as www-data
# check if exists first (hard reset and pull instead)
sudo -u www-data git clone https://github.com/chrispalmeri/various-scripts.git /home/www-data/app
# copy www to www
rsync -av --delete --delete-excluded --include='www/***' --include='php/***' --exclude='*' /home/www-data/app/ /srv/app/


# Add another PHP .ini to be parsed after the defaults
cat > /etc/php/7.3/apache2/conf.d/90-custom.ini << EOF
date.timezone = America/Chicago
error_log = $build/log/php-error.log
EOF

# Overwrite default Apache .conf file
cat > /etc/apache2/sites-available/000-default.conf << EOF
<VirtualHost *:80>
    ServerName example.com

    DocumentRoot $serve/www

    <Directory $serve/www>
        Options -Indexes +FollowSymLinks -MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog $build/log/apache-error.log
    CustomLog $build/log/apache-access.log combined
</VirtualHost>
EOF

# Enable mod rewrite and restart Apache
a2enmod rewrite
systemctl restart apache2
