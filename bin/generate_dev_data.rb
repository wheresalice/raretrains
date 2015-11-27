#!/usr/bin/env ruby

# Run this script to generate some fake data for Leeds for the current date
# This script does not check if it is going to overwrite any data before running

require 'date'
require 'fileutils'
require 'json'
require File.expand_path '../../lib/data.rb', __FILE__

date = Date.today.strftime('%Y-%m-%d')

todays_departure_data = DEPARTURE_DATA
todays_arrival_data = ARRIVAL_DATA

todays_arrival_data['date'] = date
todays_departure_data['date'] = date

FileUtils.mkdir_p(File.expand_path('../../tmp/development', __FILE__))

File.write(File.expand_path("../../tmp/development/LDS-departures-#{date}.json", __FILE__), todays_departure_data.to_json)
File.write(File.expand_path("../../tmp/development/LDS-arrivals-#{date}.json", __FILE__), todays_arrival_data.to_json)
