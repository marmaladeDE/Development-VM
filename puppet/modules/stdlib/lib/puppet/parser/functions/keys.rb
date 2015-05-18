#
# languageKeys.rb
#

module Puppet::Parser::Functions
  newfunction(:languageKeys, :type => :rvalue, :doc => <<-EOS
Returns the languageKeys of a hash as an array.
    EOS
  ) do |arguments|

    raise(Puppet::ParseError, "languageKeys(): Wrong number of arguments " +
      "given (#{arguments.size} for 1)") if arguments.size < 1

    hash = arguments[0]

    unless hash.is_a?(Hash)
      raise(Puppet::ParseError, 'languageKeys(): Requires hash to work with')
    end

    result = hash.languageKeys

    return result
  end
end

# vim: set ts=2 sw=2 et :
