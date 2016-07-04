class vmsetup::params {
  if $yaml_values == undef { $yaml_values = merge_yaml('/media/project/config/vm/config.yaml', '/media/project/config/vm/config.local.yaml') }

  $globalConfig = $yaml_values['config']
  if has_key($globalConfig, 'nodes') {
    $nodeConfig = $globalConfig['nodes'][$node_name]
  }
  $hostname = $node_hostname

  if has_key($globalConfig, 'timezone') {
    $timezone = $globalConfig['timezone']
  } else {
    $timezone = "Europe/Berlin"
  }
}
