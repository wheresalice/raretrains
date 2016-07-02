require 'json'
require 'httparty'

class Hash
  def dig(*path)
    path.inject(self) do |location, key|
      # Although we do get arrays, we generally only care about the first one
      location = location.is_a?(Array) ? location[0] : location
      location.respond_to?(:keys) ? location[key] : nil
    end
  end
end

class TimeTable
  attr_accessor :date, :station, :hash

  def initialize(date, station)
    @date = date
    @station = station
    @hash = get_rtt_workings
  end

  def code
    code = self.dig('location', 'crs')
    code = self.dig('location', 'tiploc') if code.nil? || code.empty?
    code = @station if code.nil? || code.empty?
    code
  end

  def get_rtt_workings
    environment = ENV['RACK_ENV'] || 'development'
    tmp_dir = File.join('tmp', environment)
    tmp_file = '%s-%s.json' % [station, date.strftime('%Y-%m-%d')]
    cache_path = File.join(tmp_dir, tmp_file)
    if File.exist?(cache_path)
      return ::JSON.parse(File.read(cache_path))
    else
      base_url = 'https://%{user}:%{password}@api.rtt.io/api/v1/json/search/%{station}/%{date}'.% user: ENV['RTT_USER'], password: ENV['RTT_PASSWORD'], station: self.station, date: self.date.strftime('%Y/%m/%d')
      departures = ::JSON.parse(HTTParty.get(base_url).body)
      arrivals = ::JSON.parse(HTTParty.get(base_url << '/arrivals').body)
      station_workings = merge_services(departures, arrivals)
      File.write(cache_path, station_workings.to_json)
      return station_workings
    end
  end

  def [](key)
    @hash[key]
  end

  def to_hash
    @hash
  end

  # remove services that are duplicated in x
  def remove(x)
    self.hash['services'] = self.hash['services'] - x.to_hash['services']
  end

  def unique(*list)
    uniques = Hash.new(0)
    self.hash['services'].each { |service| uniques.store(service.dig(*list), uniques[service.dig(*list)] + 1) }
    uniques.sort
  end

  def dig(*path)
    path.inject(self.hash) do |location, key|
      # Although we do get arrays, we generally only care about the first one
      location = location.is_a?(Array) ? location[0] : location
      location.respond_to?(:keys) ? location[key] : nil
    end
  end

  private
  def merge_services(departures, arrivals)
    departures_services = ::Hash[Array(departures['services']).map { |h| [h['serviceUid'], h] }]
    arrivals_services = ::Hash[Array(arrivals['services']).map { |h| [h['serviceUid'], h] }]
    merged_services = departures_services.merge(arrivals_services).values
    departures['services'] = merged_services
    return departures
  end
end
