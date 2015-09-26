ENV['RACK_ENV'] = 'test'
ENV['TMP'] = 'spec/data'
require 'json'
require 'minitest/autorun'
require 'rack/test'
require 'fileutils'
require File.expand_path '../../findinteresting.rb', __FILE__
require File.expand_path '../../lib/data.rb', __FILE__

# Clean out test tmp directory
Dir.glob(File.expand_path '../../tmp/test/*.json', __FILE__).each { |f| File.unlink f }

FileUtils.mkdir_p(File.expand_path('../../tmp/test', __FILE__))

File.write(File.expand_path('../../tmp/test/LDS-departures-2015-08-29.json', __FILE__), DEPARTURE_DATA.to_json)
File.write(File.expand_path('../../tmp/test/LDS-arrivals-2015-08-29.json', __FILE__), ARRIVAL_DATA.to_json)