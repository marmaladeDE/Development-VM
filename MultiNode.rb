Vagrant.configure("2") do |config|
    provider = $data['provider']
    if ENV.fetch('VAGRANT_DEFAULT_PROVIDER', '').strip.empty?
        ENV['VAGRANT_DEFAULT_PROVIDER'] =  provider || 'virtualbox'
    end

    hostname = $data['hostname'] || 'project.dev'

    $data['nodes'].each do |nodeName, nodeConfig|
        config.vm.define nodeName, primary: (nodeConfig.has_key?('primary') ? nodeConfig['primary'] : false) do |node|
            if nodeConfig['vm'].has_key?('box')
                node.vm.box     = data['vm']['box'].to_s
                node.vm.box_url = data['vm']['box'].to_s
                if nodeConfig['vm'].has_key?('box-version')
                    node.vm.box_version = data['vm']['box-version'].to_s
                end
            else
                if nodeConfig['php-version'].to_s == '5.3'
                    node.vm.box     = "puppetlabs/ubuntu-12.04-64-puppet"
                    node.vm.box_url = "puppetlabs/ubuntu-12.04-64-puppet"
                    node.vm.box_version = "1.0.1"
                elsif nodeConfig['php-version'].to_s == '5.4'
                    node.vm.box     = "puppetlabs/debian-7.8-64-puppet"
                    node.vm.box_url = "puppetlabs/debian-7.8-64-puppet"
                    node.vm.box_version = "1.0.2"
                else
                    node.vm.box     = "puppetlabs/ubuntu-14.04-64-puppet"
                    node.vm.box_url = "puppetlabs/ubuntu-14.04-64-puppet"
                    node.vm.box_version = "1.0.1"
                end
            end

            nodeHostname = (nodeConfig.has_key?('primary') && nodeConfig['primary']) ? hostname : "#{nodeName}.#{hostname}"

            node.vm.hostname = nodeHostname

            if Vagrant.has_plugin?("vagrant-cachier")
                node.cache.scope = :box
            end

            # set private network ip
            if nodeConfig['vm']['private_network_ip'].to_s != ''
                network_ip = "#{nodeConfig['vm']['private_network_ip']}"
                xdebug_remote_host = nodeConfig['vm']['private_network_gateway'].to_s
                if xdebug_remote_host == ''
                    xdebug_remote_host = network_ip.gsub(/^(\d+\.\d+\.\d+)\.\d+/, '\1.1')
                end
            elsif ENV['VAGRANT_DEFAULT_PROVIDER'] == 'vmware_fusion' || ENV['VAGRANT_DEFAULT_PROVIDER'] == 'vmware_workstation'
                network_ip =  "192.168.33.100"
                xdebug_remote_host = "192.168.33.1"
            else
                network_ip = "192.168.42.100"
                xdebug_remote_host = "192.168.42.1"
            end

            node.vm.network 'private_network', ip: network_ip

            if nodeConfig['vm'].has_key?('forwards')
                nodeConfig['vm']['forwards'].each do |forward|
                    node.vm.network :forwarded_port, host: forward['host'], guest: forward['guest']
                end
            end


            # add shared folder
            node.vm.synced_folder "../", "/media/project", id: "web",
                group: 'www-data', owner: 'vagrant', mount_options: ['dmode=775', 'fmode=664']

            node.vm.usable_port_range = (10200..10500)

            node.vm.provider :virtualbox do |virtualbox|
                virtualbox.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
                virtualbox.customize ['modifyvm', :id, '--memory', "#{nodeConfig['vm']['memory']}"]
                virtualbox.customize ['modifyvm', :id, '--cpus', "#{nodeConfig['vm']['cpus']}"]
                virtualbox.customize ['modifyvm', :id, '--name', nodeHostname]
                if nodeConfig['vm']['cpus'].to_i > 1
                    virtualbox.customize ["modifyvm", :id, "--ioapic", "on"]
                end
            end

            node.vm.provider :vmware_fusion do |v, override|
                v.vmx['memsize']  = "#{nodeConfig['vm']['memory']}"
                v.vmx['numvcpus'] = "#{nodeConfig['vm']['cpus']}"
                v.vmx['displayName'] = nodeHostname
            end

            node.vm.provider :vmware_workstation do |v, override|
                v.vmx['memsize']  = "#{nodeConfig['vm']['memory']}"
                v.vmx['numvcpus'] = "#{nodeConfig['vm']['cpus']}"
                v.vmx['displayName'] = nodeHostname
            end

            ssh_username = 'vagrant'
            $modulePaths = ["puppet/modules"]

            if File.directory?("../config/vm/puppet/modules")
                $modulePaths.push("../config/vm/puppet/modules")
            end

            if nodeConfig.has_key?('aliases') && Vagrant.has_plugin?('vagrant-hostsupdater')
                node.hostsupdater.aliases = nodeConfig['aliases']
            end

            node.vm.provision 'shell', inline: "echo Running apt-get update\napt-get -y -qq update"

            if nodeConfig.has_key?('pre-puppet')
                node.vm.provision 'shell', inline: nodeConfig['pre-puppet'].join("\n")
            end

            node.vm.provision :puppet do |puppet|
                puppet.facter = {
                    'xdebug_remote_host' => xdebug_remote_host,
                    'node_name' => nodeName,
                    'node_hostname' => nodeHostname
                }

                manifestsPath = "puppet/manifests"

                manifestFile = "#{nodeName}.pp"
                if nodeConfig.has_key?('manifest')
                    nodeManifest = nodeConfig['manifest']
                    manifestFile = "#{nodeManifest}.pp"
                end

                # Puppet manifest for the current node doesn't exist, so it have to be inside the configuration directory!
                if !File.exists?("puppet/manifests/#{manifestFile}")
                    manifestsPath = "../config/vm/puppet/manifests"
                end

                puppet.manifests_path = manifestsPath
                puppet.manifest_file  = manifestFile
                puppet.module_path    = $modulePaths
                puppet.options = "--verbose --hiera_config /vagrant/puppet/hiera.yaml"
            end

            node.vm.post_up_message = "Your machine is reachable at IP: #{network_ip}"
        end
    end

end
