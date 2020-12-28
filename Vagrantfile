Vagrant.configure("2") do |config|
  config.vm.box = "bento/debian-10.7"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.provision "shell", path: "./provision.sh"
end
