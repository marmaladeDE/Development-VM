#! /usr/bin/env ruby -S rspec
require 'spec_helper'

describe "the languageKeys function" do
  let(:scope) { PuppetlabsSpec::PuppetInternals.scope }

  it "should exist" do
    expect(Puppet::Parser::Functions.function("languageKeys")).to eq("function_keys")
  end

  it "should raise a ParseError if there is less than 1 arguments" do
    expect { scope.function_keys([]) }.to( raise_error(Puppet::ParseError))
  end

  it "should return an array of languageKeys when given a hash" do
    result = scope.function_keys([{'a'=>1, 'b'=>2}])
    # =~ performs 'array with same elements' (set) matching
    # For more info see RSpec::Matchers::MatchArray
    expect(result).to match_array(['a','b'])
  end
end
