# Alternative gdebi-based package provider for Puppet
#
# Copyright 2015 Chris Pick
# Licensed under the Apache License, Version 2.0

Puppet::Type.type(:package).provide(:gdebi, :parent => :dpkg, :source => :dpkg) do
  desc "Package management via `gdebi`.  Because this only uses `gdebi`
    and not `apt`, you must specify the source of any packages you want
    to manage."

  commands :gdebi => "/usr/bin/gdebi"

  def install
    unless file = @resource[:source]
      raise ArgumentError, "You cannot install gdebi packages without a source"
    end

    args = []

    # We always unhold when installing to remove any prior hold.
    self.unhold

    args << '-n'

    if @resource[:configfiles] == :keep
      args << '-o' << 'DPkg::Options::=--force-confold'
    else
      args << '-o' << 'DPkg::Options::=--force-confnew'
    end
    args << file

    gdebi(*args)
  end
end
