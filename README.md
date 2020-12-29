# various-scripts

Apache and PHP, GitHub app can update itself

## Locally

  * `git clone git@github.com:chrispalmeri/various-scripts.git`
  * Create `.env` file
  * `vagrant up`
  * View it at http://localhost:8080/
  * Make code changes

## Production

  * Update env's `sudo nano /etc/environment`
  * In home dir `git clone https://github.com/chrispalmeri/various-scripts.git`
  * `cd various-scripts/`
  * `sudo ./install.sh`
  * View it at your server's address
  * Update app from the UI

Alternately

  * curl -O https://raw.githubusercontent.com/chrispalmeri/various-scripts/master/install.sh
  * chmod +x install.sh
  * sudo ./install.sh

## Testing

  * You can `vagrant ssh` and `sudo ./install.sh` (either from /vagrant or /home/www-data/app)
  * Will change web root, and update should work
  * You will no longer be serving your local copy though, and have to `vagrant provision` to revert
