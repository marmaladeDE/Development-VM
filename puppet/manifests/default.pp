node default {
  Exec { path => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin" ] }

  if $yaml_values == undef { $yaml_values = loadyaml('/vagrant/config.yaml') }
  if $hostname == undef {$hostname = $yaml_values['vagrant']['vm']['hostname']}
  if $phpVersion == undef {$phpVersion = $yaml_values['config']['php-version']}
  if $install_elasticsearch == undef {$install_elasticsearch = $yaml_values['config']['install_elasticsearch']}
  if $install_zendguardloader == undef {$install_zendguardloader = $yaml_values['config']['install_zendguardloader']}
  if $install_ioncubeloader == undef {$install_ioncubeloader = $yaml_values['config']['install_ioncubeloader']}



  class { "vmsetup":
    phpVersion => $phpVersion,
    hostname   => $hostname,
    install_elasticsearch => $install_elasticsearch,
    install_zendguardloader => $install_zendguardloader,
    install_ioncubeloader => $install_ioncubeloader
  }
}
