class vmsetup::elasticsearch () {

  Exec { path => [ "/bin", "/sbin", "/usr/bin", "/usr/sbin", "/usr/local/bin", "/usr/local/sbin" ] }

    exec { 'add_elasticsearch_key':
      command => 'curl -L --silent "https://packages.elasticsearch.org/GPG-KEY-elasticsearch" | sudo apt-key add -',
      unless  => 'apt-key list | grep -q elasticsearch'
    }

    apt::source { 'elasticsearch.org':
        ensure => present,
        location => 'http://packages.elasticsearch.org/elasticsearch/1.4/debian',
        release  => 'stable',
        repos    => 'main',
        require  => Exec["add_elasticsearch_key"],
        include_src => false
    }

    package { 'elasticsearch':
        ensure => installed,
        require => [
            Apt::Source['elasticsearch.org'],
            Package['oracle-java8-installer']
        ]
    }

    service {'elasticsearch':
        ensure => running,
        hasrestart => true,
        hasstatus => true,
        enable => true,
        require => Package['elasticsearch']
    }

    exec { 'elasticsearch::enable mvel':
        command => '/usr/share/elasticsearch/bin/plugin -i elasticsearch/elasticsearch-lang-mvel/1.4.1',
        unless  => "/usr/share/elasticsearch/bin/plugin -l | grep -q 'lang-mvel'",
        require => Package['elasticsearch'],
        notify => Service['elasticsearch']
    }

    exec { 'elasticsearch::enable analysis-icu':
        command => '/usr/share/elasticsearch/bin/plugin -i elasticsearch/elasticsearch-analysis-icu/2.4.3',
        unless  => "/usr/share/elasticsearch/bin/plugin -l | grep -q 'analysis-icu'",
        require => Package['elasticsearch'],
        notify => Service['elasticsearch']
    }

    exec { 'elasticsearch::enable analysis-combo':
        command => '/usr/share/elasticsearch/bin/plugin -i com.yakaz.elasticsearch.plugins/elasticsearch-analysis-combo/1.5.1',
        unless  => "/usr/share/elasticsearch/bin/plugin -l | grep -q 'analysis-combo'",
        require => Package['elasticsearch'],
        notify => Service['elasticsearch']
    }

    exec { 'elasticsearch::enable dynamic scripting':
        command => 'echo script.disable_dynamic: false >> /etc/elasticsearch/elasticsearch.yml',
        unless => "cat /etc/elasticsearch/elasticsearch.yml | grep -q 'script.disable_dynamic: false'",
        require => Package['elasticsearch'],
        notify => Service['elasticsearch']
    }

    exec { 'elasticsearch::set script.default_lang':
        command => "echo \"script.default_lang: 'mvel'\" >> /etc/elasticsearch/elasticsearch.yml",
        unless => "cat /etc/elasticsearch/elasticsearch.yml | grep -q \"script.default_lang: 'mvel'\"",
        require => [
            Package['elasticsearch'],
            Exec['elasticsearch::enable dynamic scripting']
        ],
        notify => Service['elasticsearch']
    }

}