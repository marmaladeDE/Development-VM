node default {
  Exec { path => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin" ] }
  include vmsetup::params
  include vmsetup::common

  package { "nginx":
    ensure  => latest,
    require => Exec['apt_update']
  }

  service { "nginx":
    ensure     => running,
    hasstatus  => true,
    hasrestart => true,
    require    => Package["nginx"]
  }

  class {"nginx::proxy":
    listen_ip => $::vmsetup::params::nodeConfig['vm']['private_network_ip'],
    proxies => $::vmsetup::params::nodeConfig['proxies'],
    server_name => $::vmsetup::params::hostname,
    nodes => $::vmsetup::params::globalConfig['nodes']
  }

}
