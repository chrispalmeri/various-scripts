#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Don't let WSL ruin it for everyone with it's virtualizatiion
# features that botch the hashes for ubuntu archives
mkdir /etc/gcrypt
cat > /etc/gcrypt/hwf.deny << EOF
all
EOF

# From .env file
# strip windows carriage returns
# ensure ends with linebreak
# and source environment variables
sed -i 's/\r//g' /vagrant/.env
sed -i -e '$a\' /vagrant/.env
source /vagrant/.env

# Timezone
cp /usr/share/zoneinfo/America/Chicago /etc/localtime

# Make a log directory
mkdir -p /vagrant/log

# Update and install software
apt-get update
#apt-get upgrade
apt-get install -y apache2 sqlite3 php libapache2-mod-php php-curl php-sqlite3

# Add another PHP .ini to be parsed after the defaults
cat > /etc/php/7.4/apache2/conf.d/99-custom.ini << EOF
date.timezone = America/Chicago
error_log = /vagrant/log/php-error.log
EOF

# Overwrite default Apache .conf file
cat > /etc/apache2/sites-available/000-default.conf << EOF
<VirtualHost *:80>
    ServerName example.com

    DocumentRoot /vagrant/www

    <Directory /vagrant/www>
        Options -Indexes +FollowSymLinks -MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /vagrant/log/apache-error.log
    CustomLog /vagrant/log/apache-access.log combined
</VirtualHost>
EOF

# Copy environment variables from .env
# if not a comment and not blank
# into apache format env.conf
while read -r line; do
  if [[ $line != \#* ]] && [[ -n "$line" ]]; then
    key=$(echo $line | cut -f 1 -d "=")
    value=$(echo $line | cut -f 2- -d "=")
    echo "SetEnv $key $value" >> /tmp/env.conf
  fi
done < /vagrant/.env

# Move to apache conf available
mv /tmp/env.conf /etc/apache2/conf-available/

# Enable config and mod rewrite and restart Apache
a2enconf env
a2enmod rewrite
systemctl restart apache2
