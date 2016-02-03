class nginx::proxy (
  $listen_ip,
  $listen_port = 80,
  $server_name,
  $proxies,
  $nodes
) {
  Exec { path => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin" ] }
  include vmsetup::params
  include vmsetup::common

  file { "/etc/nginx/sites-available/proxy":
    content => template('nginx/proxy_config.erb'),
    require => Package["nginx"]
  }

  file { "/etc/nginx/sites-enabled/proxy":
    ensure  => link,
    target  => "/etc/nginx/sites-available/proxy",
    require => File["/etc/nginx/sites-available/proxy"],
    notify  => Service["nginx"]
  }

  file { "/etc/nginx/sites-enabled/default":
    ensure  => absent,
    require => Package["nginx"],
    notify  => Service["nginx"]
  }
}
