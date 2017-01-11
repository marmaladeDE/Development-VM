node default {
  Exec { path => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin" ] }
  include vmsetup::params
  include vmsetup::common

  $nodeConfig = $::vmsetup::params::nodeConfig

  if has_key($nodeConfig, 'aliases') {
    $vhost_aliases = $nodeConfig['aliases']
  } else {
    $vhost_aliases = { }
  }

  class { "vmsetup::php":
    version                 => $nodeConfig['php-version'],
    xdebug_remote_host      => $xdebug_remote_host,
    install_zendguardloader => $nodeConfig['install-zendguardloader'],
    install_ioncubeloader   => $nodeConfig['install-ioncubeloader']
  }

  class { "vmsetup::apache":
    hostname          => $::vmsetup::params::hostname,
    use_shared_folder => $nodeConfig['use-shared-folder'],
    webroot           => $nodeConfig['webroot'],
    php_version       => $nodeConfig['php-version'],
    vhost_port        => $nodeConfig['vhost-port'],
    vhost_aliases     => $vhost_aliases
  }

  if $nodeConfig['install-elasticsearch'] {
    $mysql_total_mem = floor($nodeConfig['vm']['memory'] * 0.4)
  } else {
    $mysql_total_mem = floor($nodeConfig['vm']['memory'] * 0.5)
  }
  $key_buffer_size = floor($mysql_total_mem * 0.25)
  $innodb_buffer_pool_size = floor($mysql_total_mem * 0.75)

  $override_options = {
    'mysqld' => {
      'bind-address' => "0.0.0.0",
      'key_buffer_size' => "${key_buffer_size}M",
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

  if $nodeConfig['install-elasticsearch'] {
    contain vmsetup::java

    class { "vmsetup::elasticsearch":
      version => $nodeConfig['elastic-version'],
      heapSize => floor($::vmsetup::params::nodeConfig['vm']['memory'] * 0.3),
    }
  }
}
