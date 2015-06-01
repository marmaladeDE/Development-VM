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
  $webroot = 'web',
  $hostname,
  $xdebug_remote_host,
  $install_zendguardloader = true,
  $install_ioncubeloader = false,
  $install_elasticsearch = false,
  $use_shared_folder     = true
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
    xdebug_remote_host => $xdebug_remote_host,
    install_zendguardloader => $install_zendguardloader,
    install_ioncubeloader => $install_ioncubeloader
  }

  class { "vmsetup::apache":
    hostname => $hostname,
    use_shared_folder => $use_shared_folder,
    webroot => $webroot
  }

  class { "mysql::server":
    require => Exec["apt_update"]
  }

  class { "mysql::client":
    require => Exec["apt_update"]
  }

  augeas { "set mysql bind-address":
    changes => [
      "set /files/etc/mysql/my.cnf/target[3]/bind-address 0.0.0.0"
    ],
    require => Service['mysqld']
  }

  file { "/home/vagrant/.my.cnf":
    content => "[client]
user=root
password=root",
    mode => 0600,
    owner => 'vagrant',
    group => 'vagrant',
    require => Service["mysqld"]
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

  augeas { "set umask":
    changes => [
      "set /files/etc/login.defs/UMASK 0002"
    ]
  }

  file_line { "set umask for existing users (interactive)":
    path => "/etc/pam.d/common-session",
    match => "session optional pam_umask.so",
    line => "session optional pam_umask.so"
  }

  file_line { "set umask for existing users (non-interactive)":
    path => "/etc/pam.d/common-session-noninteractive",
    match => "session optional pam_umask.so",
    line => "session optional pam_umask.so"
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

  exec { "usermod -g www-data -aG vagrant vagrant": }

  file { "/etc/bash_completion.d/bash_aliases":
    ensure  => file,
    content => "alias ls='ls --color=auto'
alias dir='ls -al'
alias grep='grep --color=auto'"
  }

}
