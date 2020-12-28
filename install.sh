#!/bin/bash

# be running as root
if [[ $EUID != 0 ]]; then
  echo "This script needs to be run as root." >&2
  exit 1
fi

# install software
source software.sh

# give www-data a proper home directory
# that's the user php will run commands as
# want it to have a place to put stuff
# where it has permission to `git pull` later
mkdir -p /home/www-data
chown www-data:www-data /home/www-data
# need to stop apache while modifying the user
systemctl stop apache2
usermod -d /home/www-data www-data
#systemctl start apache2

# clone repo as www-data
# check if exists first (hard reset and pull instead)
sudo -u www-data git clone https://github.com/chrispalmeri/various-scripts.git /home/www-data/app

# copy www to www
#rsync -av --delete /home/www-data/app/www/ /var/www/html
rsync -av --delete --delete-excluded --include='www/***' --include='php/***' --exclude='*' /home/www-data/app/ /srv/app/

#logs i suppose can go in /home/www-data/app/log/
mkdir -p /home/www-data/app/log

# Overwrite default Apache .conf file
cat > /etc/apache2/sites-available/000-default.conf << EOF
<VirtualHost *:80>
    ServerName example.com

    DocumentRoot /srv/app/www/

    <Directory /srv/app/www/>
        Options -Indexes +FollowSymLinks -MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /home/www-data/app/log/apache-error.log
    CustomLog /home/www-data/app/log/apache-access.log combined
</VirtualHost>
EOF

systemctl restart apache2
