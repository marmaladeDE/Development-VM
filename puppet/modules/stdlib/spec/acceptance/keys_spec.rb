#! /usr/bin/env ruby -S rspec
require 'spec_helper_acceptance'

describe 'languageKeys function', :unless => UNSUPPORTED_PLATFORMS.include?(fact('operatingsystem')) do
  describe 'success' do
    it 'keyss hashes' do
      pp = <<-EOS
      $a = {'aaa'=>'bbb','ccc'=>'ddd'}
      $o = languageKeys($a)
      notice(inline_template('languageKeys is <%= @o.sort.inspect %>'))
      EOS

      apply_manifest(pp, :catch_failures => true) do |r|
        expect(r.stdout).to match(/languageKeys is \["aaa", "ccc"\]/)
      end
    end
    it 'handles non hashes'
    it 'handles empty hashes'
  end
  describe 'failure' do
    it 'handles improper argument counts'
  end
end
