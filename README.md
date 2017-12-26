# marmalade GmbH Development-VM
This repository includes a generic VM to develop applications in PHP.

## Setup

Make sure you have vagrant and virtualbox installed on your machine.

Setup the structure like

``` 
ROOTDIR
- config
-- vm
--- config.yaml [copy from THIS_REPO/config.yaml.dist with your settings]
- vm
-- HERE_THE_CONTENT_OF_THIS_REPO
```
To mount your project files into the VM with the use of shared folders, you can specify them in your `config.yaml`.
The `config.yaml.dist` contains a full multi-node example configuration. 

You can use this snippet to create the correct folder-structure.

```
mkdir marmalade_vm
cd marmalade_vm
mkdir -p config/vm
mkdir web
git clone https://github.com/marmaladeDE/Development-VM.git vm
cp vm/config.yaml.dist config/vm/config.yaml
```

## User and Passwords

__SSH:__ ubuntu / ubuntu

__MYSQL:__ root / root

## Tools
You could reach the Elasticsearch HEAD-Plugin via http://head.<VM-Hostname>/_plugin/head/

## Issues and Help

### SSH connection fails

__Error:__

If you get an error like
``` 
  default: SSH auth method: private key
  default: Warning: Connection timeout. Retrying...
``` 
you've probably have

* a firewall that blocks it
* an anti virus program with an firewall running
* Hyper-V running and blocking

__Solution:__

Turn it off an test it again.

### Forwarding Ports ###

If you want to access your box from other computers in the network, you might want to forward Ports from the Box.
Thats easy.

__Solution:__

Specify the array vm.forwards like shown in the following example whre we forward the ports 80 and 9200
```
    forwards:
      - apache:
        host: 80
        guest: 80
      - elasticsearch
        host: 9200
        guest: 9200
```
Or the shorthand version:
```
    forwards:
      - apache: { host: 80, guest: 80 }
      - elasticsearch: { host: 9200, guest: 9200 }
```

### Elasticsearch gets not installed ###

Do you get problems with installing elasticsearch? There are some know issues:

* You must specify a exact version number

__Solution:__ 

Elasticsearch veriosn must be set with three digits like 1.4.2, 1.7.6, 2.4.2 or similar.
Only Elasticsearch 2.1.0 and up is supported. Take a look to
 https://github.com/jprante/elasticsearch-analysis-decompound#decompound-plugin-for-elasticsearch
for a full list of supported ES versions.
