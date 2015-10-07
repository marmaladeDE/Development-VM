# marmalade GmbH Development-VM
This repository includes a generic VM to develop applications in PHP.

## Setup

Make sure you have vagrant and virtualbox installed on your machine.

Setup the structure like

``` 
ROOTDIR
- config
-- vm
--- config.yaml [copy from THIS_REPO/example_config.yaml with your settings]
- vm
-- HERE_THE_CONTENT_OF_THIS_REPO
- web
-- YOUR_PROJECT_FILES_HERE
``` 

## User and Passwords

__SSH:__ vagrant / vagrant

__MYSQL:__ root / root

## Tools
You could reach the Elasticsearch HEAD-Plugin via http://YOURIP:9200/_plugin/head/

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
* an anti virus programm with an firewall running
* hyperv running and blocking

__Solution:__

Turn it off an test it again.

### merge_yaml Error

__Error:__

``` 
  ==> default: Error: Could not autoload puppet/parser/functions/merge_yaml: cannot load such file -- active_support on node localhost
  The SSH command responded with a non-zero exit status. Vagrant
  assumes that this means the command failed. The output for this command
  should be in the log above. Please read the output to determine what
  went wrong.
```

__Solution:__

Please DON'T use in the config.yaml not the Top Level Domain ".dev" or ".local" as this is somehow reserved in newer versions of vagrant.

