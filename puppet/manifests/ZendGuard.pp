file { "/usr/lib/php5/modules/php54/ZendGuardLoader.so":
  source  => "/vagrant/puppet/files/zendguard/php-5.4.x/ZendGuardLoader.so",
  require => File["/usr/lib/php5/modules/php54"]
}
file { "/etc/php5/apache2/conf.d/99-zendguard.ini":
  ensure  => present,
  content => "zend_extension=/usr/lib/php5/modules/php54/ZendGuardLoader.so
zend_loader.enable=1
zend_loader.disable_licensing=0",
  notify  => Service["httpd"],
  require => [
    Package["php5"],
    File["/usr/lib/php5/modules/php54/ZendGuardLoader.so"]
  ]
}