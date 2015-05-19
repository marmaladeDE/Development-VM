# == Class: vmsetup
#
# Full description of class vmsetup here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'vmsetup':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2015 Your name here, unless otherwise noted.
#
class vmsetup (
  $phpVersion = '5.4',
  $hostname,
  $install_zendguardloader = true,
  $install_ioncubeloader = false,
  $install_elasticsearch = false
) {

  class { 'apt':
    always_apt_update    => false,
    apt_update_frequency => undef,
    disable_keys         => undef,
    proxy_host           => false,
    proxy_port           => '8080',
    purge_sources_list   => false,
    purge_sources_list_d => false,
    purge_preferences_d  => false,
    update_timeout       => undef,
    fancy_progress       => undef
  }

  class { "vmsetup::php":
    version => $phpVersion,
    install_zendguardloader => $install_zendguardloader,
    install_ioncubeloader => $install_ioncubeloader
  }

  class { "vmsetup::apache":
    hostname => $hostname
  }

  class { "mysql::server":
    require => Exec["apt_update"]
  }

  class { "mysql::client":
    require => Exec["apt_update"]
  }

  contain vmsetup::java

  exec { 'set mysql root password':
    command  => 'mysqladmin -u root -s password root',
    onlyif   => 'mysqladmin -u root -s status | grep -q Uptime',
    require  => [
      Package['mysql-server'],
      Package['mysql-client']
    ],
    notify   => Service['mysql']
  }

  augeas { "set_umask":
    changes => [
      "set /files/etc/login.defs/UMASK 0002"
    ]
  }

  if $install_elasticsearch {
    include vmsetup::elasticsearch
  }

  package {
    [
      "vim",
      "unzip",
      "python-software-properties"
    ]:
      ensure  => latest,
      notify  => Service["httpd"],
      require => Exec["apt_update"]
  }

#   file { "/etc/php5/mods-available/xdebug.ini":
#     content => "zend_extension=xdebug.so
# xdebug.cli_color=1
# xdebug.max_nesting_level=500
# xdebug.remote_enable=1
# xdebug.remote_host=192.168.56.1
# xdebug.var_display_max_children=512
# xdebug.var_display_max_data=2560
# xdebug.var_display_max_depth=200",
#     notify  => Service["httpd"],
#     require => Package["php5"]
#   }

#  file { "/etc/php5/mods-available/opcache.ini":
#    content => "zend_extension=opcache.so
#opcache.enable=1
#opcache.cli_enable=1",
#    notify  => Service["httpd"],
#    require => Package["php5"]
#  }
#
#  file { "/etc/php5/mods-available/date.ini":
#    content => "[Date]
#date.timezone = Europe/Berlin",
#    notify  => Service["httpd"],
#    require => Package["php5"]
#  }
#
#  exec{ "php5enmod date":
#    notify  => Service["httpd"],
#    require => Package["php5"]
#  }
#
#  file { "/etc/bash_completion.d/bash_aliases.sh":
#    ensure  => file,
#    content => "alias ls='ls --color=auto'
#alias dir='ls -al'
#alias grep='grep --color=auto'"
#  }
#

#
#  exec { "usermod -g www-data -aG vagrant vagrant": }
}
