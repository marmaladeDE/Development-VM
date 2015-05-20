class vmsetup::java {
  Exec { path => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin" ] }

  include '::apt'

  apt::source { "source_java8":
    location    =>'http://ppa.launchpad.net/webupd8team/java/ubuntu',
    release     => 'trusty',
    repos       => 'main',
    include_src => false
  }

  exec { 'add_webupd8_key':
    command => 'apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886',
    unless  => 'apt-key list | grep -q EEA14886',
    notify => Exec['apt_update']
  }

  exec { 'accept oracle java license':
    command => 'echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections',
    unless => "debconf-show oracle-java8-installer | grep -q 'shared/accepted-oracle-license-v1-1: true'",
    require => Exec['add_webupd8_key']
  }

  package { ["oracle-java8-installer","oracle-java8-set-default"]:
    ensure => present,
    require => [
      Exec['accept oracle java license'],
      Exec['apt_update']
    ]
  }
}