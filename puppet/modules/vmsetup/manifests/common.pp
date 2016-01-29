class vmsetup::common {
  class { 'apt':
    always_apt_update    => false,
    apt_update_frequency => undef,
    disable_keys         => undef,
    proxy_host           => false,
    proxy_port           => '8080',
    purge_sources_list   => false,
    purge_sources_list_d => false,
    purge_preferences_d  => false,
    update_timeout       => undef,
    fancy_progress       => undef
  }

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

  exec { "usermod -g www-data -aG vagrant vagrant": }

  exec { 'echo "vagrant:vagrant" | chpasswd': }

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

}
