require 'rspec'
require 'date'
require File.expand_path '../spec_helper.rb', __FILE__
require File.expand_path '../../lib/time_table.rb', __FILE__

describe 'TimeTable' do

  it 'should do something' do

    timetable = TimeTable.new(Date.today, 'LDS')
  end
end