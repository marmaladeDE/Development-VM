# -*- mode: ruby -*-
# vi: set ft=ruby :

dir = File.dirname(File.expand_path(__FILE__))
configPath = File.expand_path("#{dir}/../config/vm")

require 'yaml'
require "#{dir}/lib/ruby/deep_merge.rb"
require "#{dir}/lib/ruby/cidr.rb"

configValues = YAML.load_file("#{configPath}/config.yaml")

if configValues.has_key?('imports')
    importedConfig = {}
    configValues['imports'].each do |importFile|
        if File.file?("#{configPath}/#{importFile}")
            imported = YAML.load_file("#{configPath}/#{importFile}")
            importedConfig.deep_merge!(imported)
        end
    end
    configValues.deep_merge!(importedConfig)
end

if File.file?("#{configPath}/config.local.yaml")
    custom = YAML.load_file("#{configPath}/config.local.yaml")
    if custom.has_key?('imports')
        customImportedConfig = {}
        custom['imports'].each do |importFile|
            if File.file?("#{configPath}/#{importFile}")
                customImported = YAML.load_file("#{configPath}/#{importFile}")
                customImportedConfig.deep_merge!(customImported)
            end
        end
        custom.deep_merge!(customImportedConfig)
    end
    configValues.deep_merge!(custom)
end

Vagrant.require_version '>= 1.8.0'

Vagrant.configure("2") do |config|

    hostname = configValues['hostname'] || "project.vm"

    ansible_groups = configValues['groups']

    ipIndex = 1
    ipConfig = CIDR.new(configValues['network-ip'])
    netmask = ipConfig.netmask.ip
    availableIps = ipConfig.range
    hostIp = availableIps[0]
    mysqlNetworkMask = hostIp.gsub(/\d+$/, '%')
    mysqlIp = ""
    hostIps = {}

    configValues['nodes'].each do |nodeName, nodeConfig|
        if nodeConfig['type'] == 'mysql'
            mysqlIp = availableIps[ipIndex]
        end
        hostIps[nodeName] = availableIps[ipIndex]
        ipIndex += 1
    end

    config.vm.provision "shell", preserve_order: true do |shell|
        shell.path = "shell/init"
    end

    config.vm.provision "main", preserve_order: true, type: 'ansible_local' do |ansible|
        ansible.playbook = "ansible/sites.yml"
        ansible.become = true
        ansible.groups = ansible_groups
    end

    vmConfigPath = "/tmp/config/vm"
    config.vm.synced_folder configPath, vmConfigPath
    if configValues.has_key?('customPlaybook')
        config.vm.provision "custom", preserve_order: true, type:'ansible_local' do |ansible|
            ansible.playbook = "#{vmConfigPath}/#{configValues['customPlaybook']}"
            ansible.become = true
            ansible.groups = ansible_groups
        end
    end

    configValues['nodes'].each do |nodeName, nodeConfig|
        isPrimaryNode = (nodeConfig.has_key?('primary') ? nodeConfig['primary'] : false)

        config.vm.define nodeName, primary: isPrimaryNode do |node|
            node.vm.box = nodeConfig['vm']['box'] || "ubuntu/xenial64"
            node.vm.usable_port_range = (10200..10500)

            node.vm.hostname = isPrimaryNode ? hostname : "#{nodeName}.#{hostname}"
            node.vm.network "private_network", ip: hostIps[nodeName], netmask: netmask

            if nodeConfig['vm'].has_key?('shared-folders')
                nodeConfig['vm']['shared-folders'].each do |hostPath, guestPath|
                    node.vm.synced_folder hostPath, guestPath
                end
            end

            if nodeConfig['vm'].has_key?('port-forwards')
                nodeConfig['vm']['port-forwards'].each do |hostPort, guestPort|
                    node.vm.network :forwarded_port, host: hostPort, guest: guestPort
                end
            end

            node.vm.provider :virtualbox do |virtualbox|
                virtualbox.memory = nodeConfig['vm']['memory']
                virtualbox.cpus = nodeConfig['vm']['cpus']
                virtualbox.name = node.vm.hostname
                virtualbox.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
                virtualbox.customize ["modifyvm", :id, "--uartmode1", "disconnected"]

                if nodeConfig['cpus'].to_i > 1
                    virtualbox.ioapic = true
                end
            end

            ansible_extra_vars = {
                "hostname": node.vm.hostname,
                "vm_ip": hostIps[nodeName],
                "ssh_user": nodeConfig.has_key?('ssh_user') ? nodeConfig['ssh_user'] : "ubuntu",
                "mysql": {
                    "server_ip": mysqlIp,
                    "network_mask": mysqlNetworkMask
                },
                "config_path": vmConfigPath || "/vagrant"
            }

            ansible_extra_vars.deep_merge!(nodeConfig)

            if ansible_extra_vars.has_key?('php')
                ansible_extra_vars['php']['configs']['xdebug']['remote_host'] = hostIp
            end

            node.vm.provision "main", type: 'ansible_local' do |ansible|
                ansible.compatibility_mode = "2.0"
                ansible.extra_vars = ansible_extra_vars
            end

            if configValues.has_key?('customPlaybook')
                node.vm.provision "custom", type:'ansible_local' do |ansible|
                    ansible.extra_vars = ansible_extra_vars
                    ansible.compatibility_mode = "2.0"
                end
            end

            node.vm.post_up_message = "Your VM #{node.vm.hostname} got the IP #{hostIps[nodeName]}"
        end
    end
end
