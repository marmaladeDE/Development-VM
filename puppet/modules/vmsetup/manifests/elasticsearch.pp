class vmsetup::elasticsearch ($version = 1.4) {
  Exec { path => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin" ] }

  exec { 'add_elasticsearch_key':
    command => 'curl -L --silent "https://packages.elastic.co/GPG-KEY-elasticsearch" | sudo apt-key add -',
    unless  => 'apt-key list | grep -q elasticsearch'
  }

  apt::source { 'elasticsearch.org':
    ensure      => present,
    location    => "http://packages.elastic.co/elasticsearch/$version/debian",
    release     => 'stable',
    repos       => 'main',
    require     => Exec["add_elasticsearch_key"],
    include_src => false
  }

  package { 'elasticsearch':
    ensure  => installed,
    require => [
      Apt::Source['elasticsearch.org'],
      Package['oracle-java8-installer']
    ]
  }

  service { 'elasticsearch':
    ensure     => running,
    hasrestart => true,
    hasstatus  => true,
    enable     => true,
    require    => Package['elasticsearch'],
  }

  if ($version == '2.x') {
    exec { 'elasticsearch::enable head':
      command => '/usr/share/elasticsearch/bin/plugin install mobz/elasticsearch-head',
      unless  => "/usr/share/elasticsearch/bin/plugin list | grep -q 'head'",
      require => Package['elasticsearch'],
      notify  => Service['elasticsearch'],
    }

    exec { 'elasticsearch::enable HQ':
      command => '/usr/share/elasticsearch/bin/plugin install royrusso/elasticsearch-HQ',
      unless  => "/usr/share/elasticsearch/bin/plugin list | grep -q 'hq'",
      require => Package['elasticsearch'],
      notify  => Service['elasticsearch'],
    }

    exec { 'elasticsearch::enable analysis-icu':
      command => '/usr/share/elasticsearch/bin/plugin install analysis-icu',
      unless  => "/usr/share/elasticsearch/bin/plugin list | grep -q 'analysis-icu'",
      require => Package['elasticsearch'],
      notify  => Service['elasticsearch']
    }

    exec { 'elasticsearch::enable dynamic scripting':
      command => 'echo script.inline: on >> /etc/elasticsearch/elasticsearch.yml',
      unless  => "cat /etc/elasticsearch/elasticsearch.yml | grep -q 'script.inline: on'",
      require => Package['elasticsearch'],
      notify  => Service['elasticsearch']
    }

    exec { 'elasticsearch::disable local ip binding':
      command => 'echo network.host: 0.0.0.0 >> /etc/elasticsearch/elasticsearch.yml',
      unless  => "cat /etc/elasticsearch/elasticsearch.yml | grep -q 'network.host: 0.0.0.0'",
      require => Package['elasticsearch'],
      notify  => Service['elasticsearch']
    }
  }
  if (is_numeric($version) and $version >= 1.4 and $version < 2.0) {
    if ($version == 1.4) {
      $mvel_plugin_version = '1.4.1'
    }
    if ($version == 1.5) {
      $mvel_plugin_version = '1.5.0'
    }
    if ($version == 1.6) {
      $mvel_plugin_version = '1.6.0'
    }
    if ($version == 1.7) {
      $mvel_plugin_version = '1.7.0'
    }
    exec { 'elasticsearch::enable marvel':
      command => '/usr/share/elasticsearch/bin/plugin -i elasticsearch/marvel/latest',
      unless  => "/usr/share/elasticsearch/bin/plugin -l | grep -q 'marvel'",
      require => Package['elasticsearch'],
      notify  => Service['elasticsearch'],
    }
    exec { 'elasticsearch::disable marvel agent':
      command => 'echo marvel.agent.enabled: false >> /etc/elasticsearch/elasticsearch.yml',
      unless  => "cat /etc/elasticsearch/elasticsearch.yml | grep -q 'marvel.agent.enabled: false'",
      require => [Package['elasticsearch'], Exec['elasticsearch::enable marvel']],
      notify  => Service['elasticsearch'],
    }

    exec { 'elasticsearch::enable head':
      command => '/usr/share/elasticsearch/bin/plugin -i mobz/elasticsearch-head',
      unless  => "/usr/share/elasticsearch/bin/plugin -l | grep -q 'head'",
      require => Package['elasticsearch'],
      notify  => Service['elasticsearch'],
    }

    exec { 'elasticsearch::enable HQ':
      command => '/usr/share/elasticsearch/bin/plugin -i royrusso/elasticsearch-HQ/v1.0.0',
      unless  => "/usr/share/elasticsearch/bin/plugin -l | grep -q 'HQ'",
      require => Package['elasticsearch'],
      notify  => Service['elasticsearch'],
    }

    exec { 'elasticsearch::enable mvel':
      command => "/usr/share/elasticsearch/bin/plugin -i elasticsearch/elasticsearch-lang-mvel/$mvel_plugin_version",
      unless  => "/usr/share/elasticsearch/bin/plugin -l | grep -q 'lang-mvel'",
      require => Package['elasticsearch'],
      notify  => Service['elasticsearch']
    }

    exec { 'elasticsearch::enable analysis-icu':
      command => '/usr/share/elasticsearch/bin/plugin -i elasticsearch/elasticsearch-analysis-icu/2.4.3',
      unless  => "/usr/share/elasticsearch/bin/plugin -l | grep -q 'analysis-icu'",
      require => Package['elasticsearch'],
      notify  => Service['elasticsearch']
    }

    exec { 'elasticsearch::enable analysis-combo':
      command => '/usr/share/elasticsearch/bin/plugin -i com.yakaz.elasticsearch.plugins/elasticsearch-analysis-combo/1.5.1',
      unless  => "/usr/share/elasticsearch/bin/plugin -l | grep -q 'analysis-combo'",
      require => Package['elasticsearch'],
      notify  => Service['elasticsearch']
    }

    exec { 'elasticsearch::enable dynamic scripting':
      command => 'echo script.disable_dynamic: false >> /etc/elasticsearch/elasticsearch.yml',
      unless  => "cat /etc/elasticsearch/elasticsearch.yml | grep -q 'script.disable_dynamic: false'",
      require => Package['elasticsearch'],
      notify  => Service['elasticsearch']
    }

    exec { 'elasticsearch::set script.default_lang':
      command => "echo \"script.default_lang: 'mvel'\" >> /etc/elasticsearch/elasticsearch.yml",
      unless  => "cat /etc/elasticsearch/elasticsearch.yml | grep -q \"script.default_lang: 'mvel'\"",
      require => [
        Package['elasticsearch'],
        Exec['elasticsearch::enable dynamic scripting']
      ],
      notify  => Service['elasticsearch']
    }
  }
}
