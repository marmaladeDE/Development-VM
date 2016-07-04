class vmsetup::common {
  include vmsetup::params
  include apt

  augeas { "set umask":
    changes => [
      "set /files/etc/login.defs/UMASK 0002"
    ]
  }

  file_line { "set umask for existing users (interactive)":
    path  => "/etc/pam.d/common-session",
    match => "session optional pam_umask.so",
    line  => "session optional pam_umask.so"
  }

  file_line { "set umask for existing users (non-interactive)":
    path  => "/etc/pam.d/common-session-noninteractive",
    match => "session optional pam_umask.so",
    line  => "session optional pam_umask.so"
  }

  package {
    [
      "vim",
      "unzip",
      "python-software-properties"
    ]:
      ensure  => latest,
      require => Exec["apt_update"]
  }

  user { "vagrant":
    password => pw_hash('vagrant', 'SHA-512', 'v2'),
    gid => 'www-data',
    groups => ['www-data', 'vagrant']
  }

  file { "/etc/bash_completion.d/bash_aliases":
    ensure  => file,
    content => join([
      "alias ls='ls --color=auto'",
      "alias ll='ls -lF'",
      "alias dir='ls -al'",
      "alias grep='grep --color=auto'"
    ], "\n")
  }

  exec { "Generate german locale":
    command => "locale-gen de_DE.UTF-8",
    unless  => "locale -a | grep -q de_DE.utf8",
  }

  class {"vmsetup::timezone": timezone => $::vmsetup::params::timezone}
}
