# == Class: gdebi
#
# Install gdebi.
#
# === Examples
#
#  include gdebi
#
# === Authors
#
# Chris Pick <puppetgdebi@chrispick.com>
#
# === Copyright
#
# Copyright 2015 Chris Pick
# Licensed under the Apache License, Version 2.0
#

class gdebi {
    package { 'gdebi-core': }
}
