# This isn't part of the main website, it's used to tweet out newly found trains and needs more work to be fully portable
#
require 'redis'
require 'json'
require 'date'
require 'twitter'

require_relative 'lib/helpers'

include Helpers

run_date = ARGV[0].nil? ? Date.today : Date.parse(ARGV[0])
station = ARGV[1] || 'LDS'
ENV['RACK_ENV'] = ENV['RACK_ENV'] || 'development'

#puts "Loading #{station} data for #{run_date} in #{ENV['RACK_ENV']} mode"

departures = get_rtt_workings(run_date, station.upcase, 'departures')['services']
arrivals = get_rtt_workings(run_date, station.upcase, 'arrivals')['services']

services = merge_services(departures, arrivals)

#puts "Loaded #{services.length} services"

pairings = services.map do |s|
  {:origin => s['locationDetail']['origin'][0]['description'],
   :destination => s['locationDetail']['destination'][0]['description'],
   :toc => s['atocCode']}
end.uniq

#puts "#{run_date}: #{pairings.length} unique origin/destination/toc pairings for #{station}"

redis = Redis.new

new_pairings = []

pairings.each do |p|
  redis_key = "#{p[:origin].gsub(' ','.')}:#{station}:#{p[:destination].gsub(' ','.')}:#{p[:toc]}"
  found = redis.getset(redis_key, 1)
  unless found
    new_pairings << p
  end
  redis.expire(redis_key, 691200) # 8 days
end

#puts "#{run_date}: #{new_pairings.length} new services identified for #{station}"

client = Twitter::REST::Client.new do |config|
  config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
  config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
  config.access_token_secret = ENV['TWITTER_ACCESS_TOKEN_SECRET']
end

if new_pairings.length == 0
  client.update("#{Date.today.strftime('%Y-%m-%d')}: No new services identified for today")
end

new_pairings.each do |p|
  pairing_services = services.select do |s|
    s['locationDetail']['origin'][0]['description'] == p[:origin] &&
        s['locationDetail']['destination'][0]['description'] == p[:destination] &&
        s['atocCode'] == p[:toc]
  end
  service = pairing_services[0]
  service_rundate = Date.parse(service['runDate'])
  message =  "#{run_date}: #{pairing_services.length} services from #{p[:origin]} to #{p[:destination]} run by #{p[:toc]} http://www.realtimetrains.co.uk/train/#{service['serviceUid']}/#{service_rundate.strftime('%Y/%m/%d')}/advanced"
  puts message
  client.update(message)
end
