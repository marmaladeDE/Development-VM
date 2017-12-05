# -*- mode: ruby -*-
# vi: set ft=ruby :

dir = File.dirname(File.expand_path(__FILE__))
configPath = File.expand_path("#{dir}/../config/vm")

require 'yaml'
require "#{dir}/lib/ruby/deep_merge.rb"
require "#{dir}/lib/ruby/cidr.rb"

configValues = YAML.load_file("#{configPath}/config.yaml")

if File.file?("#{configPath}/config.local.yaml")
  custom = YAML.load_file("#{configPath}/config.local.yaml")
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

                if nodeConfig['cpus'].to_i > 1
                    virtualbox.ioapic = true
                end
            end

            node.vm.provision "shell" do |shell|
                shell.path = "shell/init"
            end

            ansible_extra_vars = {
                "hostname": node.vm.hostname,
                "vm_ip": hostIps[nodeName],
                "ssh_user": nodeConfig.has_key?('ssh_user') ? nodeConfig['ssh_user'] : "ubuntu",
                "mysql": {
                    "server_ip": mysqlIp,
                    "network_mask": mysqlNetworkMask
                }
            }

            ansible_extra_vars.deep_merge!(nodeConfig)

            if ansible_extra_vars.has_key?('php')
                ansible_extra_vars['php']['configs']['xdebug']['remote_host'] = hostIp
            end

            node.vm.provision "main", type: 'ansible_local' do |ansible|
                ansible.playbook = "ansible/sites.yml"
                ansible.become = true
                ansible.compatibility_mode = "2.0"
                ansible.groups = ansible_groups
                ansible.extra_vars = ansible_extra_vars
            end
            
            if nodeConfig.has_key?('customPlaybook')
                customPlaybookPath = "/tmp/config/vm"
                node.vm.synced_folder configPath, customPlaybookPath
                node.vm.provision "custom", type:'ansible_local' do |ansible|
                    ansible.playbook = "#{customPlaybookPath}/#{nodeConfig['customPlaybook']}"
                    ansible.become = true
                    ansible.compatibility_mode = "2.0"
                    ansible.groups = ansible_groups
                    ansible.extra_vars = ansible_extra_vars
                end
            end

            node.vm.post_up_message = "Your VM #{node.vm.hostname} got the IP #{hostIps[nodeName]}"
        end
    end
end
