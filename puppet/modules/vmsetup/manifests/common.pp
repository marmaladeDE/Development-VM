class vmsetup::common {
  include vmsetup::params

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

  file { "/usr/local/sbin/check-primary-group":
    content => "#/bin/sh
if [ $# -ne 2]; then
    echo \"Usage: \$0 <Group> <User>\"
    exit 255
fi

GROUP=$(grep -E \"^\$1\" /etc/group)
if [ $? -ne 0 ]; then
    exit 1
fi

GID=$(echo \$GROUP|cut -d\":\" -f 3)

PGROUP=$(grep -E \"^\$2\" /etc/passwd)
if [ $? -ne 0 ]; then
    exit 1
fi

PGID=$(echo \$PGROUP|cut -d\":\" -f 4)

[ \$GID -eq \$PGID ];
",
    mode => "+x"
  }
  exec { "usermod -g www-data -aG vagrant vagrant":
    unless => "check-primary-group www-data vagrant"
  }

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

  class {"vmsetup::timezone": timezone => $::vmsetup::params::timezone}
}
