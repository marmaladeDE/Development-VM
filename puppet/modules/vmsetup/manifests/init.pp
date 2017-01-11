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
  $phpVersion = 5.4,
  $webroot = 'web',
  $hostname,
  $xdebug_remote_host,
  $install_zendguardloader = true,
  $install_ioncubeloader = false,
  $install_elasticsearch = false,
  $use_shared_folder     = true,
  $elastic_version = 1.4,
  $install_mysql = true,
  $vhost_port = 80,
  $vhost_aliases = { }
) {

  include apt

  class { "vmsetup::php":
    version                 => $phpVersion,
    xdebug_remote_host      => $xdebug_remote_host,
    install_zendguardloader => $install_zendguardloader,
    install_ioncubeloader   => $install_ioncubeloader
  }

  class { "vmsetup::apache":
    hostname          => $hostname,
    use_shared_folder => $use_shared_folder,
    webroot           => $webroot,
    php_version       => $phpVersion,
    vhost_port        => $vhost_port,
    vhost_aliases     => $vhost_aliases
  }

  if $install_mysql {
    if $install_elasticsearch {
      $mysql_total_mem = floor($::vmsetup::params::globalConfig['vm']['memory'] * 0.4)
    } else {
      $mysql_total_mem = floor($::vmsetup::params::globalConfig['vm']['memory'] * 0.5)
    }
    $key_buffer_size = floor($mysql_total_mem * 0.25)
    $innodb_buffer_pool_size = floor($mysql_total_mem * 0.75)

    $override_options = {
      'mysqld' => {
        'bind-address'            => "0.0.0.0",
        'key_buffer_size'         => "${key_buffer_size}M",
        'innodb_buffer_pool_size' => "${innodb_buffer_pool_size}M"
      }
    }

    class { 'mysql::server':
      override_options => $override_options,
      require          => Exec["apt_update"]
    }

    class { "mysql::client":
      require => Exec["apt_update"]
    }

    exec { "set MySQL-Root permissions for Host":
      command => "mysql -uroot -proot -e \"GRANT ALL PRIVILEGES ON *.* TO root@$xdebug_remote_host IDENTIFIED BY 'root'\"",
      unless  => "test $(mysql -sNe \"SELECT COUNT(*) FROM mysql.user WHERE Host = '$xdebug_remote_host' AND User = 'root'\") -gt 0",
      require => [
        Package['mysql-server'],
        Package['mysql_client'],
        Exec['set mysql root password']
      ]
    }

    file { "/home/vagrant/.my.cnf":
      content => "[client]
user=root
password=root",
      mode    => "u=rw,og-rwx",
      owner   => 'vagrant',
      group   => 'vagrant',
      require => Package["mysql_client"]
    }

    exec { 'set mysql root password':
      command  => 'mysqladmin -u root -s password root',
      onlyif   => 'mysqladmin -u root -s status | grep -q Uptime',
      require  => [
        Package['mysql-server'],
        Package['mysql_client']
      ],
      notify   => Service['mysql']
    }
  }

  if $install_elasticsearch {
    contain vmsetup::java
  }

  if $install_elasticsearch {
    class { "vmsetup::elasticsearch":
      version => $elastic_version,
      heapSize => floor($::vmsetup::params::nodeConfig['vm']['memory'] * 0.3),
    }
  }
}
