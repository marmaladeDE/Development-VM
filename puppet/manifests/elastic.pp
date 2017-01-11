node default {
  Exec { path => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin" ] }
  include vmsetup::params
  include vmsetup::common

  contain vmsetup::java

  $es_heap_size = floor($::vmsetup::params::nodeConfig['vm']['memory'] * 0.5)

  class { "vmsetup::elasticsearch":
    version => $::vmsetup::params::nodeConfig['elastic-version'],
    heap_size => "${es_heap_size}m",
  }

  if defined("vmcustoms::$node_name") {
    class { "vmcustoms::$node_name":
      config => $yaml_values
    }
  }
}
