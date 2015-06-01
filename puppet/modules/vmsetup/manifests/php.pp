class vmsetup::php (
  $version = '5.4',
  $install_zendguardloader = true,
  $install_ioncubeloader = false,
  $xdebug_remote_host = ''
) {
  case $version {
    '5.5': {
      $dotdeb = false
      $release = 'ppa:ondrej/php5'
      $install_apc = false
      $install_xdebug = true
      $xdebug_path = 'xdebug.so'
    }
    '5.6': {
      $dotdeb = false
      $release = 'ppa:ondrej/php5-5.6'
      $install_apc = false
      $install_xdebug = true
      $xdebug_path = 'xdebug.so'
    }
    '5.4': {
      $dotdeb = true
      $release = 'wheezy'
      $install_apc = true
      $install_xdebug = true
      $xdebug_path = '/usr/lib/php5/20100525/xdebug.so'
    }
  }

  include '::apt'

  if $dotdeb {
    $location     = 'http://packages.dotdeb.org'
    $repos        = 'all'
    $include_src  = false

    apt::source { 'dotdeb-wheezy':
      location    => $location,
      release     => 'wheezy',
      repos       => $repos,
      include_src => $include_src,
    }

    exec { 'add_dotdeb_key':
      command => 'curl -L --silent "http://www.dotdeb.org/dotdeb.gpg" | apt-key add -',
      unless  => 'apt-key list | grep -q dotdeb',
      notify => Exec['apt_update']
    }
  } else {
    package{ 'software-properties-common':
      ensure => latest,
    }
    exec { 'ondrey:ppa' :
      command => "add-apt-repository ${release}",
      notify => Exec['apt_update'],
      require => Package['software-properties-common']
    }
  }

  # php5-mhash and php5-json are provided by php5-common
  package {
  [
    "php-pear",
    "php5",
    "php5-common",
    "php5-cli",
    "php5-curl",
    "php5-dev",
    "php5-gd",
    "php5-imagick",
    "php5-intl",
    "php5-mcrypt",
    "php5-mysqlnd",
    "php5-recode",
    "php5-xsl"
  ]:
    ensure  => latest,
    notify  => Service["httpd"],
    require => [
      Exec["apt_update"],
      Package["httpd"]
    ]
  }

  # php5-xdebug is currently not available for php 5.6 on debian wheezy
  if $install_xdebug {
    package { "php5-xdebug":
      ensure  => latest,
      notify  => Service["httpd"],
      require => [
        Exec["apt_update"]
      ]
    }
  }

  if $install_apc {
    package { "php-apc":
        ensure  => latest,
        notify  => Service["httpd"],
        require => [
          Exec["apt_update"],
        ]
    }
  }

  file { ["/usr/lib/php5/modules","/usr/lib/php5/modules/php${version}"]:
    ensure  => directory,
    recurse => true,
    owner   => 'vagrant',
    group   => 'www-data',
    require => [
      Package["httpd"],
      Package["php5"]
    ]
  }

  if $install_zendguardloader {
    class { "vmsetup::zendguardloader":
      version => $version
    }
  }
  if $install_ioncubeloader {
    class { "vmsetup::ioncubeloader":
      version => $version
    }
  }

  file { "/etc/php5/mods-available/custom.ini":
    content => "
display_errors=on
post_max_size=32M
upload_max_filesize=32M
memory_limit=128M
max_execution_time=300

[Date]
date.timezone = Europe/Berlin
",
    require => Package["php5"]
  }

  exec{ "php5enmod custom":
    notify  => Service["httpd"],
    require => File["/etc/php5/mods-available/custom.ini"]
  }


  file { "/etc/php5/mods-available/xdebug.ini":
    content => "zend_extension=${xdebug_path}
xdebug.cli_color=1
xdebug.max_nesting_level=500
xdebug.remote_enable=1
xdebug.remote_host=${xdebug_remote_host}
xdebug.idekey=PHPSTORM
xdebug.var_display_max_children=512
xdebug.var_display_max_data=2560
xdebug.var_display_max_depth=200",
    notify  => Service["httpd"],
    require => Package["php5"]
  }

  if $version != '5.4' {
    file { "/etc/php5/mods-available/opcache.ini":
      content => "zend_extension=opcache.so
opcache.enable=1
opcache.cli_enable=1",
      notify  => Service["httpd"],
      require => Package["php5"]
    }
  }

}
