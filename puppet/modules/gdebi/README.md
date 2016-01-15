# gdebi

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with gdebi](#setup)
    * [What gdebi affects](#what-gdebi-affects)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

Package provider that uses gdebi to install a Debian package (.deb) file with its dependencies

## Module Description

The dpkg provider can also install a package from a .deb file, but it will not
install any needed dependencies first.

The apt provider can install a package and its dependencies, but the package
must be fetched from a repository, not a local .deb file.

The gdebi provider fills this gap.

## Setup

### What gdebi affects

* Installs the 'gdebi-core' package.
* Installs any requested pakage along with its dependencies.

## Usage

    include gdebi

    package { 'foo':
        provider => gdebi,
        source   => "/path/to/foo.deb",
    }

## Limitations

Compatible with Ubuntu and Debian.

## Development

Please report issues or create pull requests on github:
https://github.com/cpick/puppet-gdebi
