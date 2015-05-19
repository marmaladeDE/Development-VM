class vmsetup::php (
  $version = '5.4',
  $install_zendguardloader = true,
  $install_ioncubeloader = false
) {
  case $version {
    '5.5': {
      $release = 'wheezy-php55'
      $install_apc = false
    }
    '5.6': {
      $release = 'wheezy-php56'
      $install_apc = false
    }
    default: {
      $release = 'wheezy'
      $install_apc = true
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
    "php5-json",
    "php5-mcrypt",
    "php5-mhash",
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
    include vmsetup::zendguardloader
  }
  if $install_ioncubeloader {
    include vmsetup::ioncubeloader
  }

}