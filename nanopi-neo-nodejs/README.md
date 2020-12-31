# nanopi-neo-nodejs

Provision a Node.js app on a local NanoPi Neo

  * NanoPi Neo
  * Armbian
  * Node.js
  * NGINX
  * Let’s Encrypt
  * UncomplicatedFirewall

Will use DNS validation to get a LetsEncrypt wildcard cert to use locally - if
there is a local domain in use and and the required environment variable set to
manage the domain in DigitalOcean.

Can also push the cert to a local Unraid box and AdvancedTomato router after receiving it.

## Hardware setup

Download [Armbian][1] Bionic image and [7-Zip][2] to extract it.

Use [Etcher][4] to flash the image onto your [SD card][3].

Boot your [NanoPi Neo][5] with the SD card and use [Putty][6] to access it.

  [1]: https://www.armbian.com/nanopi-neo/
  [2]: https://www.7-zip.org/
  [3]: https://shop.sandisk.com/store/sdiskus/en_US/pd/productID.5163153100/SanDisk-Ultra-microSDXC-UHSI-Card-32GB-A1C10U1
  [4]: https://www.balena.io/etcher/
  [5]: https://www.friendlyarm.com/index.php?route=product/product&path=69&product_id=132
  [6]: https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html

## Initial config

* login as `root` using `1234`
* change password
* new user wizard
  * password
  * skip all the questions
* `apt update`
* `DEBIAN_FRONTEND=noninteractive apt upgrade -y`
* `armbian-config`
    * System > Install > Install/Update the bootloader on SD/eMMC > Yes
    * Ok > Back
    * Personal > Hostname > type a new hostname
    * Ok > Ok > Back > Exit
* `shutdown -r now` to reboot

## Usage

Use your new username and password

`sudo nano /etc/environment` and add env variables like:

```
UNRAID_USER=root
UNRAID_HOST=tower
TOMATO_USER=root
TOMATO_HOST=tomato
SSHPASS=password
ACME_DNS=dns_dgon
DO_API_KEY=1234567890
```

`git clone https://github.com/chrispalmeri/nanopi-neo-nodejs.git`

`cd nanopi-neo-nodejs`

`sudo ./provision.sh github-user/repo-name`

## To do

  * it should work to install a second app from another repo
    * app needs to support ENV for port
    * script needs to pick an unused port
    * nginx needs to put it under a path
  * add code to repair NGINX
    * cause unclean shutdown can corrupt the config
  * install Fail2ban
  * double check systemd service options
    * on boot nginx starts before the app so you get 502 for a minute
  * if acme issue skips, then should skip the install 

## Notes

Tomato has (I think by default) ssh limited to 3 connections per 60 seconds
you need to up that to 5

If you want to `npm install sqlite3` you are going to have a bad time.