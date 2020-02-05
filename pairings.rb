# This isn't part of the main website, it's used to tweet out newly found trains and needs more work to be fully portable
#
require 'redis'
require 'json'
require 'date'
require 'twitter'
require 'uri'

require_relative 'lib/time_table.rb'
run_date = Date.today
station = 'LDS'
client = Twitter::REST::Client.new do |config|
  config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
  config.access_token = ENV['TWITTER_ACCESS_TOKEN']
  config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
end

ENV['RACK_ENV'] = ENV['RACK_ENV'] || 'development'

puts "Loading #{station} data for #{run_date} in #{ENV['RACK_ENV']} mode"

begin
  timetable = TimeTable.new(run_date, station)
rescue => e
  puts 'failed to connect to RTT'
  puts e
  # client.update("@alicefromonline I couldn't connect to RTT today") unless ENV['RACK_ENV'] == 'development'
  exit 1
end
services = timetable['services']

puts "Loaded #{services.length} services"

pairings = services.map do |s|
  {origin: s['locationDetail']['origin'][0]['description'],
   destination: s['locationDetail']['destination'][0]['description'],
   toc: s['atocCode']}
end.uniq

puts "#{run_date}: #{pairings.length} unique origin/destination/toc pairings for #{station}"

if ENV['REDISTOGO_URL']
  redis_uri = URI.parse(ENV['REDISTOGO_URL'])
  redis = Redis.new(host: redis_uri.host, port: redis_uri.port, password: redis_uri.password)
else
  redis = Redis.new
end

new_pairings = []

begin
  pairings.each do |p|
    redis_key = "#{p[:origin].gsub(' ', '.')}:#{station}:#{p[:destination].gsub(' ', '.')}:#{p[:toc]}"
    found = redis.getset(redis_key, 1)
    new_pairings << p unless found
    redis.expire(redis_key, 691_200) # 8 days
  end
rescue => e
  puts 'Failed to connect to Redis'
  client.update("@alicefromonline I couldn't connect to Redis today") unless ENV['RACK_ENV'] == 'development'
end

# puts "#{run_date}: #{new_pairings.length} new services identified for #{station}"

new_pairings.each do |p|
  pairing_services = services.select do |s|
    s['locationDetail']['origin'][0]['description'] == p[:origin] &&
        s['locationDetail']['destination'][0]['description'] == p[:destination] &&
        s['atocCode'] == p[:toc]
  end
  message = "#{run_date}: #{pairing_services.length} services from #{p[:origin]} to #{p[:destination]} run by #{p[:toc]} "
  message << "due to cancellation (#{pairing_services[0]['locationDetail']['cancelReasonCode']}) " unless pairing_services[0]['locationDetail']['cancelReasonCode'].nil?
  message << URI.encode("https://leedstrains.herokuapp.com/LDS/services?date=#{Date.today}&origin=#{p[:origin]}&destination=#{p[:destination]}&operator=#{p[:toc]}")
  puts message
  client.update(message) unless ENV['RACK_ENV'] == 'development'
end
