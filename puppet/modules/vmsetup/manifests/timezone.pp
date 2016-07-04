class vmsetup::timezone ($timezone = "Europe/Berlin") {
  file {"/etc/timezone":
    content => $timezone,
    notify => Exec["Apply timezone"]
  }

  exec {"Apply timezone":
    command => "/usr/sbin/dpkg-reconfigure -f noninteractive tzdata",
    unless => "test \"$timezone\" = \"$(cat /etc/timezone)\""
  }
}
