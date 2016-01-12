class vmsetup::zendguardloader ($mod_path, $conf_path, $version = 5.4) {

  file { "$mod_path/ZendGuardLoader.so":
    source  => "/vagrant/puppet/files/zendguard/php${version}/ZendGuardLoader.so",
    require => File["$mod_path"]
  }

  file { "$conf_path/zendguard.ini":
    ensure  => present,
    content => "; priority=99
zend_extension=$mod_path/ZendGuardLoader.so
zend_loader.enable=1
zend_loader.disable_licensing=0",
    notify  => Service["httpd"],
    require => [
      Package[$::vmsetup::php::php_prefix],
      File["$mod_path"]
    ]
  }

  if $version > 5.3 {
    exec { "$::vmsetup::php::phpenmod zendguard/99":
      notify  => Service['httpd'],
      require => File["$conf_path/zendguard.ini"]
    }
  }


  if $version > 5.4 {
    file { "$mod_path/opcache_zgl.so":
      source  => "/vagrant/puppet/files/zendguard/php${version}/opcache.so",
      require => File["$mod_path"]
    }

    file { "$conf_path/opcache.ini":
      content => join([
        "zend_extension=$mod_path/opcache_zgl.so",
        "opcache.enable=1",
        "opcache.cli_enable=1"
      ], "\n"),
      notify  => Service["httpd"],
      require => [Package[$::vmsetup::php::php_prefix], File["$mod_path/opcache_zgl.so"]]
    }
  }
}

