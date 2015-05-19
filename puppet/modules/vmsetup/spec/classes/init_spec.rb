require 'spec_helper'
describe 'vmsetup' do

  context 'with defaults for all parameters' do
    it { should contain_class('vmsetup') }
  end
end
