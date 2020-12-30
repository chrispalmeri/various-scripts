#!/bin/bash

# Don't let WSL ruin it with virtualizatiion features
# that botch the hashes for package archives
mkdir -p /etc/gcrypt
cat > /etc/gcrypt/hwf.deny << EOF
all
EOF

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
