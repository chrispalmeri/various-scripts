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
mkdir /home/www-data
chown www-data:www-data /home/www-data
# need to stop apache while modifying the user
systemctl stop apache2
usermod -d /home/www-data www-data
systemctl start apache2

# clone repo as www-data
sudo -u www-data git clone https://github.com/chrispalmeri/various-scripts.git /home/www-data/app

# copy www to www
rsync -av --delete /home/www-data/app/www/ /var/www/html

# not really sure where to put php /var/www/php/?
# or do you just do whatever and change the apache config?
# /var/www/sites/example.com/php/ (also /www/)
