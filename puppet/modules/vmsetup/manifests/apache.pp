class vmsetup::apache ($hostname) {

  $projectDir = "/srv/${hostname}"
  $docRoot = "${projectDir}/web"

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

  file { 'docroot' :
    path    => $projectDir,
    ensure  => directory,
    owner   => 'vagrant',
    group   => 'www-data',
    require => Package["httpd"]
  }
  file { 'link-share':
    path   => $docRoot,
    ensure => link,
    target => '/media/project/web',
    force  => true
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
    require  => [
        File['docroot'],
        File['link-share']
     ],
    servername => $hostname
  }
}

