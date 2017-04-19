#!/usr/bin/env ruby
# cidr.rb
# (mostly by charles hooper, with cidr notation support tacked on by bwolfe)

# Copyright (c) 2014 Bucky Wolfe
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# == Copyright
# Copyright (c) 2009, Charles Hooper
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# * Neither the name of Plumata LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific prior
# written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.

# CIDR: Takes subnet in cidr notation and returns information about it.
class CIDR
  attr_reader :ip, :netmask

  def initialize(subnetwork)
    # subnetwork should be an IP with CIDR notation
    # like: "192.168.0.1/24"
    ip, prefix = subnetwork.split '/'
    @ip = IP.new(ip)
    @netmask = prefix_to_netmask(prefix)
  end

  def subnet
    # Subnet is calculated by ip AND'd w/ network mask
    IP.new(ip.to_i & @netmask.to_i)
  end

  def broadcast
    # Broadcast is calc'd by subnet OR'd w/ inverted network mask
    IP.new(subnet.to_i | ~@netmask.to_i)
  end

  def maxhosts
    # 2 is subtracted for subnet and broadcast address as they are unusable
    broadcast.to_i - subnet.to_i - 2
  end

  # Return an array of IPs that match
  def range
    lowend = subnet.to_i + 1
    topend = broadcast.to_i - 1
    (lowend..topend).map { |ip| IP.new(ip).to_s }
  end

  # Take a cidr prefix and spit out a IP object representing the subnet addr
  private def prefix_to_netmask(prefix)
    # binary notation for "1 * prefix" + "0 * (32bits - prefixlen)"
    # mask for /24 would = "0b11111111111111111111111100000000"
    mask = "0b#{'1' * prefix.to_i}#{'0' * (32 - prefix.to_i)}"
    IP.new(Integer(mask, 2))
  end
end

# IP: instantiated with an IP address in binary/int or human-readable string
# notation, provides methods which assist in type conversion.
class IP
  attr_reader :ip

  def initialize(ip)
    # The regex isn't perfect but I like it
    if ip.to_s =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
      @ip = ip
    else
      # Am certain there is a much more elegant way to do this
      octet = []
      octet[0] = (ip & 0xFF000000) >> 24
      octet[1] = (ip & 0x00FF0000) >> 16
      octet[2] = (ip & 0x0000FF00) >> 8
      octet[3] = ip & 0x000000FF
      @ip = octet.join('.')
    end
  end

  def to_i
    # convert ip to 32-bit long (ie: 192.168.0.1 -> 3232235521)
    ip_split = ip.split('.')
    long = ip_split[0].to_i << 24
    long += ip_split[1].to_i << 16
    long += ip_split[2].to_i << 8
    long + ip_split[3].to_i
    # should return long automagically, yeah?
  end

  def to_s
    # This class stores the IP as a string, so we just return it as-is
    @ip
  end

  def bits
    # Count number of bits used (1). This is only really useful for the netmask
    bits = 0
    octets = ip.to_s.split('.')
    octets.each do |n|
      bits += Math.log10(n.to_i + 1) / Math.log10(2) unless n.to_i == 0
    end
    bits.to_i
  end
end

if __FILE__ == $PROGRAM_NAME
  begin
    c = CIDR.new(ARGV.last)
    puts "Subnetting information for #{c.ip}/#{c.netmask.bits}"
    puts "Subnet mask: #{c.netmask}"
    puts "Network Address: #{c.subnet}"
    puts "Broadcast: #{c.broadcast}"
    puts "Max hosts: #{c.maxhosts}"
    puts "IP Range:\n" + c.range.join("\n") if ARGV.include? '-r'
  rescue
    puts <<'    EOMSG'
      Usage: #{$PROGRAM_NAME} [OPTION]... [IP/CIDR]
      example usage: #{$PROGRAM_NAME} 192.168.0.1/24

      Optional Arguments:
      -r                    Print each IP in the subnet range.
    EOMSG
  end
end