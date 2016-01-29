class vmsetup::params {
  if $yaml_values == undef { $yaml_values = merge_yaml('/media/project/config/vm/config.yaml', '/media/project/config/vm/config.local.yaml') }

  $globalConfig = $yaml_values['config']
  $nodeConfig = $globalConfig['nodes'][$node_name]
  $hostname = $node_hostname
}
