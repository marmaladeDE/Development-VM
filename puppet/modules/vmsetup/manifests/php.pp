class vmsetup::php (
  $version = '5.4',
  $install_zendguardloader = true,
  $install_ioncubeloader = false,
  $xdebug_remote_host = ''
) {
  case $version {
    '5.5': {
      $release = 'wheezy-php55'
      $install_apc = false
      $xdebug_path = 'xdebug.so'
    }
    '5.6': {
      $release = 'wheezy-php56'
      $install_apc = false
      $xdebug_path = 'xdebug.so'
    }
    default: {
      $release = 'wheezy'
      $install_apc = true
      $xdebug_path = '/usr/lib/php5/20100525/xdebug.so'
    }
  }

  $location     = 'http://packages.dotdeb.org'
  $repos        = 'all'
  $include_src  = false

  include '::apt'

  apt::source { 'dotdeb-wheezy':
    location    => $location,
    release     => 'wheezy',
    repos       => $repos,
    include_src => $include_src,
  }

  # wheezy-php55 requires both repositories to work correctly
  # See: http://www.dotdeb.org/instructions/
  if $release != 'wheezy' {
    apt::source { "source_php_${release}":
      location    => $location,
      release     => $release,
      repos       => $repos,
      include_src => $include_src,
    }
  }

  exec { 'add_dotdeb_key':
    command => 'curl -L --silent "http://www.dotdeb.org/dotdeb.gpg" | apt-key add -',
    unless  => 'apt-key list | grep -q dotdeb',
    path    => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
    notify => Exec['apt_update']
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
    "php5-xdebug",
    "php5-xsl"
  ]:
    ensure  => latest,
    notify  => Service["httpd"],
    require => [
      Apt::Source["dotdeb-wheezy"],
      Exec["apt_update"],
      Package["httpd"]
    ]
  }
  if $install_apc {
    package { "php-apc":
        ensure  => latest,
        notify  => Service["httpd"],
        require => [
          Apt::Source["dotdeb-wheezy"],
          Exec["apt_update"],
          Package["httpd"]
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
    content => "[Date]
date.timezone = Europe/Berlin

[Custom]
display_errors on
max_post_size=32M
upload_max_filesize=32M
memory_limit=128M
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