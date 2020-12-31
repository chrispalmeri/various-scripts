#!/bin/bash

# get the hostname
domain_name=$(hostname -A | tr -d '[:space:]') # e.g. "hostname.local-domain.tld" || "hostname"
cert_name="$(cut -d . -s -f 2- <<< $domain_name)" # e.g. "local-domain.tld" || ""

# repo name arg
repo="${1:-ammezie/sample-nodejs-app}" # e.g. "ammezie/sample-nodejs-app"
repo_dir="$(cut -d / -f 2- <<< $repo)" # e.g. "sample-nodejs-app"

cd ~

# get the user running the script
if [[ ! $(id -u) == 0 ]]; then
  echo "This script needs to be run as root." >&2
  exit 1
fi

if [[ $SUDO_USER ]]; then
  real_user=$SUDO_USER
else
  real_user=$(whoami)
fi

# shorter things
# real_user=$(whoami)
# [[ $real_user == "root" ]] || { echo "You are not root" ; exit 1; }
# [[ $SUDO_USER ]] && real_user=$SUDO_USER
# ! type npm > /dev/null && apt install -y npm

function is_installed() {
  if ! type "$1" &> /dev/null; then
    echo ">>> Install $1"
    apt install -y $1
  fi
}

function restart_nginx() {
  if nginx -t &> /dev/null; then
    echo -e ">>> NGINX config is \e[32mGOOD\e[0m"
    systemctl restart nginx
  else
    echo -e ">>> NGINX config is \e[31mFUCKED\e[0m"
  fi
}

function build_app() {
npm install --build-from-source=sqlite3 --sqlite=/usr/bin

npm run build

# start it
echo ">>> Start the app"

cat > /etc/systemd/system/$repo_dir.service << EOF
[Unit]
Description=$repo_dir
After=network.target

[Service]
WorkingDirectory=/home/$real_user/$repo_dir
# ExecStart=/usr/bin/node index.js
ExecStart=/usr/bin/npm start
Restart=always
# StandardOutput=syslog
# StandardError=syslog
# SyslogIdentifier=$repo_dir
User=$real_user
Environment=PORT=3000 NODE_ENV=production
# EnvironmentFile=

[Install]
WantedBy=multi-user.target
EOF

systemctl enable $repo_dir

systemctl start $repo_dir

if systemctl is-active $repo_dir &> /dev/null; then
  echo -e ">>> $repo_dir app is \e[32mUP\e[0m"
else
  echo -e ">>> $repo_dir app is \e[31mDOWN\e[0m"
fi
}

echo ">>> Update"
apt update

# not doing apt upgrade
# or u-boot update (not sure how in bash for that anyway)

is_installed npm

# add an app
if [[ ! -d $repo_dir ]]; then
  echo ">>> Clone the app"
  sudo -u $real_user git clone https://github.com/$repo.git
  cd $repo_dir
  build_app
else
  cd $repo_dir
  git fetch
  if [[ $(git rev-parse HEAD) != $(git rev-parse @{u}) ]]; then
    echo ">>> Update the app"
    git pull
    build_app
  fi
fi

cd ~

is_installed nginx

echo ">>> Configure NGINX"
cat > /etc/nginx/sites-available/$domain_name << EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name $domain_name;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
   }
}
EOF

# remove default config, and anything else
rm -f /etc/nginx/sites-enabled/*

# symlink it into sites-enabled
ln -sf /etc/nginx/sites-available/$domain_name /etc/nginx/sites-enabled/

# uncomment a thing about more storage space for the virtual host server names
sed -i 's/# server_names_hash_bucket_size/server_names_hash_bucket_size/g' /etc/nginx/nginx.conf

restart_nginx

# firewall it
is_installed ufw

echo ">>> Configure UFW"
ufw allow ssh
ufw allow http

ufw --force enable

# do this last cause it might take a while
# app is available already on http, unless you have cached 301's...
if [[ $cert_name && $ACME_DNS ]]; then

echo ">>> Found local domain $cert_name and API key"

# acme.sh letsencrypt client
if ! type ./.acme.sh/acme.sh &> /dev/null; then
  echo ">>> Install Acme.sh"
  curl https://get.acme.sh | sh
  chown -R $real_user: .acme.sh
fi

echo ">>> Issue cert"
# might take 20 minutes and show some errors trying while the dns propagates
sudo -u $real_user ./.acme.sh/acme.sh --issue --dns $ACME_DNS -d $cert_name -d *.$cert_name

if [[ $UNRAID_HOST && $TOMATO_HOST ]]; then

is_installed sshpass

cat > deploy.sh << EOF
#!/bin/bash

cd /home/$real_user/.acme.sh/$cert_name

echo "Pushing to Unraid"
cat $cert_name.key fullchain.cer > ${UNRAID_HOST}_unraid_bundle.pem
sshpass -e scp -o StrictHostKeyChecking=no ${UNRAID_HOST}_unraid_bundle.pem $UNRAID_USER@$UNRAID_HOST:/boot/config/ssl/certs
sshpass -e ssh -o StrictHostKeyChecking=no $UNRAID_USER@$UNRAID_HOST 'nginx -s reload'

echo "Pushing to Tomato"
sshpass -e scp -o StrictHostKeyChecking=no fullchain.cer $TOMATO_USER@$TOMATO_HOST:/etc/cert.pem
sshpass -e scp -o StrictHostKeyChecking=no $cert_name.key $TOMATO_USER@$TOMATO_HOST:/etc/key.pem
sshpass -e ssh -o StrictHostKeyChecking=no $TOMATO_USER@$TOMATO_HOST 'nvram set https_crt_file="\$(tar -C / -cz etc/cert.pem etc/key.pem  | openssl enc -a)"'
sshpass -e ssh -o StrictHostKeyChecking=no $TOMATO_USER@$TOMATO_HOST 'nvram commit'
sshpass -e ssh -o StrictHostKeyChecking=no $TOMATO_USER@$TOMATO_HOST 'service httpd restart'
EOF

chmod +x deploy.sh
chown -R $real_user: deploy.sh

# so, won't hurt anything, but really you shouldn't rerun this for no reason
sudo -u $real_user ./.acme.sh/acme.sh --install-cert -d $cert_name --reloadcmd /home/$real_user/deploy.sh

fi

echo ">>> Reconfig NGINX"
cat > /etc/nginx/sites-available/$domain_name << EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name $domain_name;

    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;

    server_name $domain_name;

    ssl_certificate /home/$real_user/.acme.sh/$cert_name/fullchain.cer;
    ssl_certificate_key /home/$real_user/.acme.sh/$cert_name/$cert_name.key;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Proto \$scheme;
   }
}
EOF

# update rules
echo ">>> Reconfig UFW"
ufw allow https

# restart
restart_nginx

fi