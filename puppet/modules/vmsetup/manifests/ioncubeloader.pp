class vmsetup::ioncubeloader ($mod_path, $conf_path, $version = 5.4) {

  file { "$mod_path/IoncubeLoader.so":
    source  => "/vagrant/puppet/files/ioncube/ioncube_loader_lin_${version}.so",
    require => File["$mod_path"]
  }

  file { "$conf_path/ioncube.ini":
    ensure  => present,
    content => "; priority=00
zend_extension=$mod_path/IoncubeLoader.so",
    notify  => Service["httpd"],
    require => [
      Package[$::vmsetup::php::php_prefix],
      File["$mod_path/IoncubeLoader.so"]
    ]
  }

  if $version > 5.3 {
    exec { "$::vmsetup::php::phpenmod ioncube/00":
      notify  => Service['httpd'],
      require => File["$conf_path/ioncube.ini"]
    }
  }
}

