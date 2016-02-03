node default {
  Exec { path => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin" ] }
  include vmsetup::params
  include vmsetup::common

  $override_options = {
    'mysqld' => {
      'bind-address' => "0.0.0.0",
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
    onlyif  => "test -z $(mysql -sNe \"SELECT COUNT(*) FROM mysql.user WHERE Host = '$xdebug_remote_host' AND User = 'root'\")",
    require => [
      Package['mysql-server'],
      Package['mysql-client']
    ]
  }

  file { "/home/vagrant/.my.cnf":
    content => "[client]
user=root
password=root",
    mode    => 0600,
    owner   => 'vagrant',
    group   => 'vagrant',
    require => Package["mysql-client"]
  }

  exec { 'set mysql root password':
    command  => 'mysqladmin -u root -s password root',
    onlyif   => 'mysqladmin -u root -s status | grep -q Uptime',
    require  => [
      Package['mysql-server'],
      Package['mysql-client']
    ],
    notify   => Service['mysql']
  }

  if defined("vmcustoms::$node_name") {
    class { "vmcustoms::$node_name":
      config => $yaml_values
    }
  }
}
