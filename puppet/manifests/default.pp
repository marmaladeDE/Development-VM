node default {
  Exec { path => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin" ] }

  if $yaml_values == undef { $yaml_values = loadyaml('/vagrant/config.yaml') }
  $data = $yaml_values['config']
  if $config_hostname == undef {$config_hostname = $data['hostname']}
  if $phpVersion == undef {$phpVersion = $data['php-version']}
  if $install_elasticsearch == undef {$install_elasticsearch = $data['install-elasticsearch']}
  if $install_zendguardloader == undef {$install_zendguardloader = $data['install-zendguardloader']}
  if $install_ioncubeloader == undef {$install_ioncubeloader = $data['install-ioncubeloader']}
  if $use_shared_folder == undef {$use_shared_folder = $data['use-shared-folder']}

  class { "vmsetup":
    phpVersion => $phpVersion,
    hostname   => $config_hostname,
    xdebug_remote_host => $xdebug_remote_host,
    install_elasticsearch => $install_elasticsearch,
    install_zendguardloader => $install_zendguardloader,
    install_ioncubeloader => $install_ioncubeloader,
    use_shared_folder => $use_shared_folder
  }
}
