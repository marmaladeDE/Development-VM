class vmsetup::apache ($hostname, $use_shared_folder, $webroot) {

  $hostDir = "/srv/${hostname}"
  $docRoot = "${hostDir}/web"

  class { "::apache":
    mpm_module    => "prefork",
    default_vhost => false,
    default_mods  => true,
    require       => [
      Exec["apt_update"]
    ]
  }

  include apache::mod::php
  include apache::mod::dir
  include apache::mod::rewrite

  file { $hostDir:
    ensure  => directory,
    owner   => 'vagrant',
    group   => 'www-data',
    require => Package["httpd"]
  }

  if $use_shared_folder {
    file { $docRoot:
      ensure => link,
      target => "/media/project/${webroot}",
      force  => true,
      require => File[$hostDir]
    }
  }
  else {
    file { $docRoot:
      ensure  => directory,
      mode => 'ug+rwX',
      owner   => 'vagrant',
      group   => 'www-data',
      require => File[$hostDir]
    }
  }

  apache::vhost{ 'webroot':
    priority => 00,
    port     => 80,
    manage_docroot => false,
    docroot  => $docRoot,
    docroot_group => 'www-data',
    docroot_owner => 'vagrant',
    options  => "Indexes FollowSymLinks MultiViews",
    override => 'All',
    access_log_file => "${hostname}-access.log",
    error_log_file => "${hostname}-error.log",
    require  => [
        File[$docRoot]
    ],
    servername => $hostname
  }

  exec { 'set apache umask':
    command => 'echo umask 0002 >> /etc/apache2/envvars',
    unless => "cat /etc/apache2/envvars | grep -q 'umask'",
    require => Package['httpd'],
    notify => Service['httpd']
  }

}

