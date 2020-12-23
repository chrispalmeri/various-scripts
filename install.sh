#!/bin/bash

# be running as root
# install software


echo "update home directory"

mkdir /home/www-data
chown www-data:www-data /home/www-data

systemctl stop apache2
usermod -d /home/www-data www-data
systemctl start apache2


# clone repo as www-data
sudo -u www-data git clone https://github.com/chrispalmeri/various-scripts.git /home/www-data/app


# copy www to www
# cd /home/www-data/app
# this will not affect vagrant, cool?
rsync -av --delete /home/www-data/app/www/ /var/www/html

# not really sure where to put php
#/var/www/php/
#/var/www/sites/example.com/php/ (also /www/)
#/usr/share/my-app/
