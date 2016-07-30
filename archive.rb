require_relative 'lib/time_table.rb'
require 'aws-sdk'
require 'date'

run_date = Date.today.prev_day
timetable = TimeTable.new(run_date, 'LDS')


s3 = Aws::S3::Resource.new(region: 'eu-west-1')
environment = ENV['RACK_ENV'] || 'development'

LDS = Dir.glob("tmp/#{environment}/LDS-#{run_date.to_s}.json")
LDS.each do |day|
  s3.bucket('leedstrains').object(File.basename(day)).upload_file(day)
end

