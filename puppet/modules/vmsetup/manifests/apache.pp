class vmsetup::apache ($hostname, $use_shared_folder, $webroot, $php_version, $vhost_port = 80) {

  $hostDir = "/srv/${hostname}"
  $docRoot = "${hostDir}/web"

  class { "::apache":
    mpm_module    => "prefork",
    default_vhost => false,
    default_mods  => true,
    purge_configs => false,
    require       => [
      Exec["apt_update"]
    ]
  }

  include apache::mod::dir
  include apache::mod::rewrite

  if $php_version >= 5.6 {
    class { 'apache::mod::php':
      package_name => "libapache2-mod-php$php_version"
    }
    exec { "a2dismod php5":
      require => [
        Class['::apache'],
        Class['apache::mod::php'],
        Package['httpd']
      ],
      notify  => Class['Apache::Service']
    }
  } else {
    include apache::mod::php
  }

  file { $hostDir:
    ensure  => directory,
    owner   => 'vagrant',
    group   => 'www-data',
    require => Package["httpd"]
  }

  if $use_shared_folder {
    file { $docRoot:
      ensure  => link,
      target  => "/media/project/${webroot}",
      force   => true,
      require => File[$hostDir]
    }
  }
  else {
    file { $docRoot:
      ensure  => directory,
      mode    => 'ug+rwX',
      owner   => 'vagrant',
      group   => 'www-data',
      require => File[$hostDir]
    }
  }

  apache::vhost{ 'webroot':
    priority        => 00,
    port            => $vhost_port,
    manage_docroot  => false,
    docroot         => $docRoot,
    docroot_group   => 'www-data',
    docroot_owner   => 'vagrant',
    options         => "Indexes FollowSymLinks MultiViews",
    override        => 'All',
    access_log_file => "${hostname}-access.log",
    error_log_file  => "${hostname}-error.log",
    default_vhost   => true,
    require         => [
      File[$docRoot]
    ],
    servername      => $hostname,
    notify          => Class['Apache::Service']
  }

  exec { "a2dissite 000-default.conf":
    require => Apache::Vhost['webroot'],
    notify  => Class['Apache::Service']
  }

  exec { 'set apache umask':
    command => 'echo umask 0002 >> /etc/apache2/envvars',
    unless  => "cat /etc/apache2/envvars | grep -q 'umask'",
    require => Package['httpd'],
    notify  => Class['Apache::Service']
  }

}

