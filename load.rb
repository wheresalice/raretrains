require 'csv'
require 'redis'
require 'json'

redis = Redis.new

stations = CSV.read('csv/RailReferences.csv', { headers: true})

stations.each do |station|
  redis.set("tiploc:#{station['TiplocCode']}", station.to_hash.to_json)
  redis.set("crs:#{station['CrsCode']}", station.to_hash.to_json)
end
