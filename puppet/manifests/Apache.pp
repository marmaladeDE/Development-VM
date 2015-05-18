if $yaml_values == undef { $yaml_values = loadyaml('/vagrant/config.yaml') }
if $hostname == undef {$hostname = $yaml_values['vagrant']['vm']['hostname']}
$projectDir = "/srv/${hostname}"
$docRoot = "${projectDir}/web"

  class { "apache":
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

  apache::vhost{ 'webroot':
    priority => 00,
    port     => 80,
    docroot  => $docRoot,
    docroot_group => 'www-data',
    docroot_owner => 'vagrant',
    options  => "Indexes FollowSymLinks MultiViews",
    override => 'All',
    require  => File['docroot'],
    servername => $hostname
  }

  file { 'link-share':
    path   => $docRoot,
    ensure => link,
    target => '/media/project/web',
    force  => true,
    require => Apache::Vhost['webroot']
  }