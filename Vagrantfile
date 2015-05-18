dir = File.dirname(File.expand_path(__FILE__))
vagrant_home = (ENV['VAGRANT_HOME'].to_s.split.join.length > 0) ? ENV['VAGRANT_HOME'] : "#{ENV['HOME']}/.vagrant.d"
vagrant_dot  = (ENV['VAGRANT_DOTFILE_PATH'].to_s.split.join.length > 0) ? ENV['VAGRANT_DOTFILE_PATH'] : "#{dir}/.vagrant"

require 'yaml'

configValues = YAML.load_file("#{dir}/config.yaml")

data = configValues['vagrant']

Vagrant.require_version '>= 1.6.0'

Vagrant.configure('2') do |config|
  config.vm.box     = "puppetlabs/debian-7.8-64-puppet"
  config.vm.box_url = "puppetlabs/debian-7.8-64-puppet"

  # set hostname
  if data['vm']['hostname'].to_s.strip.length != 0
    config.vm.hostname = "#{data['vm']['hostname']}"
  else
    config.vm.hostname = "project.local.de"
  end

  # set private network ip
  if data['vm']['private_network'].to_s != ''
    config.vm.network 'private_network', ip: "#{data['vm']['network']['private_network']}"
  elsif data['vm']['provider'] == 'vmware_fusion' || data['vm']['provider'] == 'vmware_workstation'
    config.vm.network 'private_network', ip: "192.168.33.100"
  else
    config.vm.network 'private_network', ip: "192.168.42.100"
  end

  # add shared folder
  config.vm.synced_folder "./", "/media/project", id: "web",
    group: 'www-data', owner: 'vagrant', mount_options: ['dmode=775', 'fmode=664']

  config.vm.usable_port_range = (10200..10500)

  unless ENV.fetch('VAGRANT_DEFAULT_PROVIDER', '').strip.empty?
    data['vm']['provider'] = ENV['VAGRANT_DEFAULT_PROVIDER'];
  end

  if data['vm']['provider'].empty? || data['vm']['provider'] == 'virtualbox'
    ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

    config.vm.provider :virtualbox do |virtualbox|
      virtualbox.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
      virtualbox.customize ['modifyvm', :id, '--memory', "#{data['vm']['memory']}"]
      virtualbox.customize ['modifyvm', :id, '--cpus', "#{data['vm']['cpus']}"]
      virtualbox.customize ['modifyvm', :id, '--name', config.vm.hostname]
    end
  end

  if data['vm']['provider'] == 'vmware_fusion' || data['vm']['provider'] == 'vmware_workstation'
    ENV['VAGRANT_DEFAULT_PROVIDER'] = (data['vm']['provider'] == 'vmware_fusion') ? 'vmware_fusion' : 'vmware_workstation'

    config.vm.provider :vmware_fusion do |v, override|
      v.vmx['memsize']  = "#{data['vm']['memory']}"
      v.vmx['numvcpus'] = "#{data['vm']['cpus']}"
      v.vmx['displayName'] = config.vm.hostname
    end
	
    config.vm.provider :vmware_workstation do |v, override|
      v.vmx['memsize']  = "#{data['vm']['memory']}"
      v.vmx['numvcpus'] = "#{data['vm']['cpus']}"
      v.vmx['displayName'] = config.vm.hostname
    end
  end

  ssh_username = 'vagrant'

  config.vm.provision :puppet do |puppet|
    puppet.facter = {
      'ssh_username'     => "#{ssh_username}",
      'provisioner_type' => ENV['VAGRANT_DEFAULT_PROVIDER'],
      'vm_target_key'    => 'vagrantfile-local',
    }
    puppet.manifests_path = "puppet/manifests"
    puppet.manifest_file  = "default.pp"
    puppet.module_path    = "puppet/modules"
    puppet.options = "--verbose --hiera_config /vagrant/puppet/hiera.yaml"

  end

=begin
  config.vm.provision :shell do |s|
    s.path = 'puphpet/shell/execute-files.sh'
    s.args = ['exec-once', 'exec-always']
  end
  config.vm.provision :shell, run: 'always' do |s|
    s.path = 'puphpet/shell/execute-files.sh'
    s.args = ['startup-once', 'startup-always']
  end
  config.vm.provision :shell, :path => 'puphpet/shell/important-notices.sh'
=end

end
