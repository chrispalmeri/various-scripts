# various-scripts

Apache and PHP, GitHub app can update itself

  * fix placeholder `app` name
  * fix apache servername
  * ENV check, but will it be available during provision
  * NOAA grid should go in DB

## Locally

  * `git clone git@github.com:chrispalmeri/various-scripts.git`
  * Create `.env` file
  * `vagrant up`
  * View it at http://localhost:8080/
  * Make code changes

## Production

  * Update env's `sudo nano /etc/environment`
  * In home dir `curl -O https://raw.githubusercontent.com/chrispalmeri/various-scripts/master/install.sh`
  * `chmod +x install.sh`
  * `sudo ./install.sh`
  * View it at your server's address
  * Update app from the UI

## Testing

  * You can test the update.php, it should work but will change web root
  * You will no longer be serving your local copy, and have to `vagrant provision` to revert
