class vmsetup::php (
  $version = 5.4,
  $install_zendguardloader = true,
  $install_ioncubeloader = false,
  $xdebug_remote_host = ''
) {
  case $version {
    5.5: {
      $dotdeb = false
      $release = 'ppa:ondrej/php'
      $install_apc = false
      $install_xdebug = true
      $skip_zendguardloader = false
      $skip_ioncubeloader = false
      $mod_path = '/usr/lib/php/20121212/'
      $conf_path = '/etc/php/5.5/mods-available/'
      $php_prefix = "php5.5"
      $phpenmod = 'phpenmod -v 5.5 -s ALL'
    }
    5.6: {
      $dotdeb = false
      $release = 'ppa:ondrej/php'
      $install_apc = false
      $install_xdebug = true
      $skip_zendguardloader = false
      $skip_ioncubeloader = false
      $mod_path = '/usr/lib/php/20131226/'
      $conf_path = '/etc/php/5.6/mods-available/'
      $php_prefix = "php5.6"
      $phpenmod = 'phpenmod -v 5.6 -s ALL'
    }
    5.4: {
      $dotdeb = true
      $release = 'wheezy'
      $install_apc = true
      $install_xdebug = true
      $skip_zendguardloader = false
      $skip_ioncubeloader = false
      $mod_path = '/usr/lib/php5/20100525/'
      $conf_path = '/etc/php5/mods-available/'
      $php_prefix = "php5"
      $phpenmod = 'php5enmod'
    }
    5.3: {
      $dotdeb = false
      $install_apc = true
      $install_xdebug = true
      $skip_zendguardloader = false
      $skip_ioncubeloader = false
      $mod_path = "/usr/lib/php5/20090626/"
      $conf_path = '/etc/php5/conf.d/'
      $php_prefix = "php5"
      $phpenmod = 'php5enmod'
    }
    7.0: {
      $dotdeb = false
      $release = 'ppa:ondrej/php'
      $install_apc = false
      $install_xdebug = true
      $skip_zendguardloader = true
      $skip_ioncubeloader = true
      $mod_path = '/usr/lib/php/20151012'
      $conf_path = '/etc/php/7.0/mods-available/'
      $php_prefix = "php7.0"
      $phpenmod = 'phpenmod -v 7.0 -s ALL'
    }
    7.1: {
      $dotdeb = false
      $release = 'ppa:ondrej/php'
      $install_apc = false
      $install_xdebug = true
      $skip_zendguardloader = true
      $skip_ioncubeloader = true
      $mod_path = '/usr/lib/php/20160303'
      $conf_path = '/etc/php/7.1/mods-available/'
      $php_prefix = "php7.1"
      $phpenmod = 'phpenmod -v 7.1 -s ALL'
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
        ensure => latest
      }

      apt::ppa { "$release":
        require => Package['software-properties-common'],
        notify => Exec['apt_update']
      }
    }
  }

  if $version < 7.0 {
    $php_mysql_package = "$php_prefix-mysqlnd"
  } else {
    $php_mysql_package = "$php_prefix-mysql"
  }
  package {
    [
      "$php_prefix",
      "$php_prefix-common",
      "$php_prefix-cli",
      "$php_prefix-bz2",
      "$php_prefix-curl",
      "$php_prefix-dev",
      "$php_prefix-gd",
      "$php_prefix-iconv",
      "$php_prefix-imagick",
      "$php_prefix-intl",
      "$php_prefix-json",
      "$php_prefix-mbstring",
      "$php_prefix-mcrypt",
      $php_mysql_package,
      "$php_prefix-phar",
      "$php_prefix-recode",
      "$php_prefix-xdebug",
      "$php_prefix-xsl",
      "$php_prefix-yaml"
    ]:
      ensure  => latest,
      notify  => Service["httpd"],
      require => [
        Exec["apt_update"],
        Package["httpd"]
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
      Package["$php_prefix"]
    ]
  }

  if $install_zendguardloader and !$skip_zendguardloader {
    class { "vmsetup::zendguardloader":
      version   => $version,
      mod_path  => $mod_path,
      conf_path => $conf_path
    }
  }
  if $install_ioncubeloader and !$skip_ioncubeloader {
    class { "vmsetup::ioncubeloader":
      version   => $version,
      mod_path  => $mod_path,
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
    require => Package["$php_prefix"]
  }

  if $version > 5.3 {
    exec { "$::vmsetup::php::phpenmod custom":
      notify  => Service['httpd'],
      require => File["$conf_path/custom.ini"]
    }

    exec { "$::vmsetup::php::phpenmod curl/20":
      notify  => Service['httpd'],
      require => Package["$php_prefix-curl"]
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
      "xdebug.var_display_max_depth=200",
      "xdebug.profiler_enable_trigger=1"
    ], "\n"),
    notify  => Service["httpd"],
    require => Package["$php_prefix"]
  }

  if ($version > 5.4 and (!$install_zendguardloader or $skip_zendguardloader)) {
    file { "$conf_path/opcache.ini":
      content => join([
        "zend_extension=$mod_path/opcache.so",
        "opcache.enable=1",
        "opcache.cli_enable=1"
      ], "\n"),
      notify  => Service["httpd"],
      require => Package["$php_prefix"]
    }
  }

}
