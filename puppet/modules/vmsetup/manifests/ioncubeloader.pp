class vmsetup::ioncubeloader ($version = '5.4') {

  file { "/usr/lib/php5/modules/php${version}/IoncubeLoader.so":
    source  => "/vagrant/puppet/files/ioncube/ioncube_loader_lin_${version}.so",
    require => File["/usr/lib/php5/modules/php${version}"]
  }

  file { "/etc/php5/mods-available/ioncube.ini":
    ensure  => present,
    content => "; priority=00
zend_extension=/usr/lib/php5/modules/php${version}/IoncubeLoader.so",
    notify  => Service["httpd"],
    require => [
      Package["php5"],
      File["/usr/lib/php5/modules/php${version}/IoncubeLoader.so"]
    ]
  }

  exec { "php5enmod ioncube/00":
    notify => Service['httpd'],
    require => File["/etc/php5/mods-available/ioncube.ini"]
  }
}

