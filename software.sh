#!/bin/bash

function is_installed() {
  if ! type "$1" &> /dev/null; then
    echo ">>> Install $1"
    apt install -y $1
  fi
}

echo "start installing software"

# Update and install software
apt-get update
#apt-get upgrade
# gonna skip that for local setup
apt-get install -y apache2 sqlite3 php libapache2-mod-php php-curl php-sqlite3

# ufw?
# is that any problem locally?

echo "finished installing software"
