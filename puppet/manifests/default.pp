node default {
  Exec { path => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin" ] }

  if $yaml_values == undef { $yaml_values = merge_yaml('/media/project/config/vm/config.yaml', '/media/project/config/vm/config.local.yaml') }

  $data = $yaml_values['config']
  if $config_hostname == undef { $config_hostname = $data['hostname'] }
  if $phpVersion == undef { $phpVersion = $data['php-version'] }
  if $install_elasticsearch == undef { $install_elasticsearch = $data['install-elasticsearch'] }
  if $install_zendguardloader == undef { $install_zendguardloader = $data['install-zendguardloader'] }
  if $install_ioncubeloader == undef { $install_ioncubeloader = $data['install-ioncubeloader'] }
  if $use_shared_folder == undef { $use_shared_folder = $data['use-shared-folder'] }
  if $webroot == undef { $webroot = $data['webroot'] }
  if $elastic_version == undef {
    if (is_numeric($data['elastic-version']) and $data['elastic-version'] >= 2.0 and $data['elastic-version'] < 3.0) {
      $elastic_version = '2.x'
    } else {
      $elastic_version = $data['elastic-version']
    }
  }
  if $install_mysql == undef { $install_mysql = $data['install-mysql'] }
  if $vhost_port == undef { $vhost_port = $data['vhost-port'] }

  class { "vmsetup":
    phpVersion              => $phpVersion,
    hostname                => $config_hostname,
    xdebug_remote_host      => $xdebug_remote_host,
    install_elasticsearch   => $install_elasticsearch,
    install_zendguardloader => $install_zendguardloader,
    install_ioncubeloader   => $install_ioncubeloader,
    use_shared_folder       => $use_shared_folder,
    webroot                 => $webroot,
    elastic_version         => $elastic_version,
    install_mysql           => $install_mysql,
    vhost_port              => $vhost_port
  }

  if defined("vmcustoms") {
    class { "vmcustoms":
      config => $yaml_values
    }
  }
}
