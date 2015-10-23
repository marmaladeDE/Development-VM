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
      $mod_path = '/usr/lib/php5/20121212/'
      $conf_path = '/etc/php5/mods-available/'
    }
    '5.6': {
      $dotdeb = false
      $release = 'ppa:ondrej/php5-5.6'
      $install_apc = false
      $install_xdebug = true
      $mod_path = '/usr/lib/php5/20131226/'
      $conf_path = '/etc/php5/mods-available/'
    }
    '5.4': {
      $dotdeb = true
      $release = 'wheezy'
      $install_apc = true
      $install_xdebug = true
      $mod_path = '/usr/lib/php5/20100525/'
      $conf_path = '/etc/php5/mods-available/'
    }
    '5.3': {
      $dotdeb = false
      $install_apc = true
      $install_xdebug = true
      $mod_path = "/usr/lib/php5/20090626/"
      $conf_path = '/etc/php5/conf.d/'
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
      notify  => Exec['apt_update']
    }
  } else {
    if $version > 5.3 {
      package{ 'software-properties-common':
        ensure => latest,
        require => Exec['apt_update']
      }
      exec { 'ondrey:ppa' :
        command => "add-apt-repository ${release}",
        notify  => Exec['apt_update'],
        require => Package['software-properties-common']
      }
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
  package { "php5-xdebug":
    ensure  => latest,
    notify  => Service["httpd"],
    require => [
      Exec["apt_update"]
    ]
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

  file { ["$mod_path"]:
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
      version => $version,
      mod_path => $mod_path,
      conf_path => $conf_path
    }
  }
  if $install_ioncubeloader {
    class { "vmsetup::ioncubeloader":
      version => $version,
      mod_path => $mod_path,
      conf_path => $conf_path
    }
  }

  file { "$conf_path/custom.ini":
    content => join([
      "display_errors=on",
      "post_max_size=32M",
      "upload_max_filesize=32M",
      "memory_limit=128M",
      "max_execution_time=300",
      "",
      "[Date]",
      "date.timezone = Europe/Berlin"
    ], "\n"),
    require => Package["php5"]
  }

  if $version > 5.3 {
    exec{ "php5enmod custom":
      notify  => Service["httpd"],
      require => File["$conf_path/custom.ini"]
    }
  }


  file { "$conf_path/xdebug.ini":
    content => join([
      "zend_extension=$mod_path/xdebug.so",
      "xdebug.cli_color=1",
      "xdebug.max_nesting_level=500",
      "xdebug.remote_enable=1",
      "xdebug.remote_host=${xdebug_remote_host}",
      "xdebug.idekey=PHPSTORM",
      "xdebug.var_display_max_children=512",
      "xdebug.var_display_max_data=2560",
      "xdebug.var_display_max_depth=200"
    ], "\n"),
    notify  => Service["httpd"],
    require => Package["php5"]
  }

  if ($version > 5.4 and !$install_zendguardloader) {
    file { "$conf_path/opcache.ini":
      content => join([
        "zend_extension=$mod_path/opcache.so",
        "opcache.enable=1",
        "opcache.cli_enable=1"
      ], "\n"),
      notify  => Service["httpd"],
      require => Package["php5"]
    }
  }

}
