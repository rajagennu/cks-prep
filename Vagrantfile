Vagrant.configure("2") do |config|


    config.vm.provider "virtualbox" do |v|
        v.memory = 2048
        v.cpus = 2
    end


    config.vm.define "cks-master" do |master|
		master.vm.box = "ubuntu/bionic64"
        master.vm.hostname = "cks-master"

        master.vm.network "private_network", ip: "192.168.56.10"  
        master.vm.provision "shell", inline: <<-SHELL
            apt-get update
            apt-get upgrade -y
            apt-get install vim curl -y
            echo "192.168.56.10 cks-master" >> /etc/hosts
            echo "192.168.56.20 cks-worker" >> /etc/hosts
        SHELL
	end

	config.vm.define "cks-worker" do |master|
		master.vm.box = "ubuntu/bionic64"
        master.vm.hostname = "cks-worker"
        master.vm.network "private_network", ip: "192.168.56.20"  
        master.vm.provision "shell", inline: <<-SHELL
            apt-get update
            apt-get upgrade -y
            apt-get install vim curl -y
            echo "192.168.56.10 cks-master" >> /etc/hosts
            echo "192.168.56.20 cks-worker" >> /etc/hosts
        SHELL
	end

    
  end
