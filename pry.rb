require 'pry'
require File.expand_path '../lib/rare_trains.rb', __FILE__
include RareTrains
ENV['RACK_ENV'] = 'development'
load_date('2015-08-29')

class Hash
  def dig(*path)
    path.inject(self) do |location, key|
      # Although we do get arrays, we generally only care about the first one
      location = location.is_a?(Array) ? location[0] : location
      location.respond_to?(:keys) ? location[key] : nil
    end
  end
end

puts 'loaded @current_day_services and @previous_day_services'

binding.pry
