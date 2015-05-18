file { "/usr/lib/php5/modules/php54/IoncubeLoader.so":
  source  => "/vagrant/puppet/files/ioncube/ioncube_loader_lin_5.4.so",
  require => File["/usr/lib/php5/modules/php54"]
}
file { "/etc/php5/apache2/conf.d/00-ioncube.ini":
  ensure  => present,
  content => "zend_extension=/usr/lib/php5/modules/php54/IoncubeLoader.so",
  notify  => Service["httpd"],
  require => [
    Package["php5"],
    File["/usr/lib/php5/modules/php54/IoncubeLoader.so"]
  ]
}