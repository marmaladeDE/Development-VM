node default {
  Exec { path => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin" ] }
  include vmsetup::params
  include vmsetup::common

  $mysql_total_mem = floor($::vmsetup::params::nodeConfig['vm']['memory'] * 0.75)
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

  if defined("vmcustoms::$node_name") {
    class { "vmcustoms::$node_name":
      config => $yaml_values
    }
  }
}
