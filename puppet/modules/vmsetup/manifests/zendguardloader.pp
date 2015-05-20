class vmsetup::zendguardloader ($version = '5.4') {

  file { "/usr/lib/php5/modules/php${version}/ZendGuardLoader.so":
    source  => "/vagrant/puppet/files/zendguard/php${version}/ZendGuardLoader.so",
    require => File["/usr/lib/php5/modules/php${version}"]
  }

  file { "/etc/php5/mods-available/zendguard.ini":
    ensure  => present,
    content => "; priority=99
zend_extension=/usr/lib/php5/modules/php${version}/ZendGuardLoader.so
zend_loader.enable=1
zend_loader.disable_licensing=0",
    notify  => Service["httpd"],
    require => [
      Package["php5"],
      File["/usr/lib/php5/modules/php${version}"]
    ]
  }

  exec { "php5enmod zendguard/99":
    notify => Service['httpd'],
    require => File["/etc/php5/mods-available/zendguard.ini"]
  }


  if $version != '5.4' {
    file { "/usr/lib/php5/modules/php${version}/opcache.so":
      source  => "/vagrant/puppet/files/zendguard/php${version}/opcache.so",
      require => File["/usr/lib/php5/modules/php${version}"]
    }

    augeas { "change opcache binary":
      changes => [
        "set /files/etc/php5/mods-available/opcache.ini/.anon/zend_extension = /usr/lib/php5/modules/php${version}/opcache.so"
      ],
      require => File["/usr/lib/php5/modules/php${version}/opcache.so"]
    }
  }
}

