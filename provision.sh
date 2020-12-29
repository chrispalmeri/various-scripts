#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

# Don't let WSL ruin it for everyone with it's virtualizatiion
# features that botch the hashes for ubuntu archives
mkdir -p /etc/gcrypt
cat > /etc/gcrypt/hwf.deny << EOF
all
EOF

# From .env file
# strip windows carriage returns
# ensure ends with linebreak
# and source environment variables
#sed -i 's/\r//g' /vagrant/.env
#sed -i -e '$a\' /vagrant/.env
#source /vagrant/.env
# not actually used within this file

# Timezone
cp /usr/share/zoneinfo/America/Chicago /etc/localtime

# Run the installer
source /vagrant/install.sh vagrant

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

# Enable config and restart Apache
a2enconf env
systemctl restart apache2
