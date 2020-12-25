# various-scripts

## Locally

`git clone git@github.com:chrispalmeri/various-scripts.git`
Create `.env` file
`vagrant up`
View it at http://localhost:8080/
Make code changes

## Production

`git clone https://github.com/chrispalmeri/various-scripts.git`
Update env's `sudo nano /etc/environment`
`sudo ./install.sh`
View it at your server's address
Update app from the UI

## Testing

You can `vagrant ssh` and `sudo ./install.sh`
Required software should all already be present
Web root is different in vagrant so should be no conflicts
Update should succeed but will not be reflected
