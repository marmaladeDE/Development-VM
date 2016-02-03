node default {
  Exec { path => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin" ] }
  include vmsetup::params
  include vmsetup::common

  $nodeConfig = $::vmsetup::params::nodeConfig

  class { "vmsetup::php":
    version                 => $nodeConfig['php-version'],
    xdebug_remote_host      => $xdebug_remote_host,
    install_zendguardloader => $nodeConfig['install-zendguardloader'],
    install_ioncubeloader   => $nodeConfig['install-ioncubeloader']
  }

  class { "vmsetup::apache":
    hostname          => $::vmsetup::params::hostname,
    use_shared_folder => $nodeConfig['use-shared-folder'],
    webroot           => $nodeConfig['webroot'],
    php_version       => $nodeConfig['php-version'],
    vhost_port        => $nodeConfig['vhost-port']
  }

  if defined("vmcustoms::$node_name") {
    class { "vmcustoms::$node_name":
      config => $yaml_values
    }
  }
}
