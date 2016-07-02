require 'rspec'
require File.expand_path '../spec_helper.rb', __FILE__
require File.expand_path '../../lib/service.rb', __FILE__

describe 'service' do
  it 'should load a service' do
    service = Service.new('U50641')
  end
end