dir = File.dirname(File.expand_path(__FILE__))
vagrant_home = (ENV['VAGRANT_HOME'].to_s.split.join.length > 0) ? ENV['VAGRANT_HOME'] : "#{ENV['HOME']}/.vagrant.d"
vagrant_dot  = (ENV['VAGRANT_DOTFILE_PATH'].to_s.split.join.length > 0) ? ENV['VAGRANT_DOTFILE_PATH'] : "#{dir}/.vagrant"

require 'yaml'
require "#{dir}/lib/ruby/deep_merge.rb"

configValues = YAML.load_file("#{dir}/../config/vm/config.yaml")

if File.file?("#{dir}/../config/vm/config.local.yaml")
  custom = YAML.load_file("#{dir}/../config/vm/config.local.yaml")
  configValues.deep_merge!(custom)
end

data = configValues['config']

Vagrant.require_version '>= 1.6.0'

Vagrant.configure('2') do |config|
  if data['vm'].has_key?('box')
    config.vm.box     = data['vm']['box'].to_s
    config.vm.box_url = data['vm']['box'].to_s
    if data['vm'].has_key?('box-version')
      config.vm.box_version = data['vm']['box-version'].to_s
    end
  else
    if data['php-version'].to_s == '5.3'
      config.vm.box     = "puppetlabs/ubuntu-12.04-64-puppet"
      config.vm.box_url = "puppetlabs/ubuntu-12.04-64-puppet"
      config.vm.box_version = "1.0.1"
    elsif data['php-version'].to_s == '5.4'
      config.vm.box     = "puppetlabs/debian-7.8-64-puppet"
      config.vm.box_url = "puppetlabs/debian-7.8-64-puppet"
      config.vm.box_version = "1.0.2"
    else
      config.vm.box     = "puppetlabs/ubuntu-14.04-64-puppet"
      config.vm.box_url = "puppetlabs/ubuntu-14.04-64-puppet"
      config.vm.box_version = "1.0.1"
    end
  end

  # set hostname
  if data['hostname'].to_s.strip.length != 0
    config.vm.hostname = "#{data['hostname']}"
  else
    config.vm.hostname = "project.local.de"
  end

  # set private network ip
  if data['vm']['private_network_ip'].to_s != ''
    network_ip = "#{data['vm']['private_network_ip']}"
    xdebug_remote_host = data['vm']['private_network_gateway'].to_s
    if xdebug_remote_host == ''
        xdebug_remote_host = network_ip.gsub(/^(\d+\.\d+\.\d+)\.\d+/, '\1.1')
    end
  elsif data['vm']['provider'] == 'vmware_fusion' || data['vm']['provider'] == 'vmware_workstation'
    network_ip =  "192.168.33.100"
    xdebug_remote_host = "192.168.33.1"
  else
    network_ip = "192.168.42.100"
    xdebug_remote_host = "192.168.42.1"
  end

  config.vm.network 'private_network', ip: network_ip

  if data['vm'].has_key?('forwards')
    data['vm']['forwards'].each { |forward|
      config.vm.network :forwarded_port, host: forward['host'], guest: forward['guest']
    }
  end


  # add shared folder
  config.vm.synced_folder "../", "/media/project", id: "web",
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
  $modulePaths = ["puppet/modules"]
  if File.directory?("../config/vm/puppet/modules")
    $modulePaths.push("../config/vm/puppet/modules")
  end

  if data.has_key?('pre-puppet')
    config.vm.provision 'shell', inline: data['pre-puppet'].join("\n")
  end

  config.vm.provision :puppet do |puppet|
    puppet.facter = {
      'xdebug_remote_host' => xdebug_remote_host
    }
    puppet.manifests_path = "puppet/manifests"
    puppet.manifest_file  = "default.pp"
    puppet.module_path    = $modulePaths
    puppet.options = "--verbose --hiera_config /vagrant/puppet/hiera.yaml"

  end

  config.vm.post_up_message = "Your machine is reachable at IP: #{network_ip}"

end
