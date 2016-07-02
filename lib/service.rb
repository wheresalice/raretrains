require 'json'
require 'httparty'
class Service
  attr_accessor :hash, :date, :service
  def initialize(service, date = Date.today)
    @service = service
    @date = date
    @hash = get_rtt_service(service, date)

  end

  def [](key)
    @hash[key]
  end
  private
  def get_rtt_service(service, date = Date.today.to_s)
    environment = ENV['RACK_ENV'] || 'development'
    tmp_dir = File.join('tmp', environment)
    cache_path = File.join(tmp_dir, "#{service}-#{date.strftime('%Y-%m-%d')}.json")
    puts cache_path
    if File.exist? cache_path
      service_data = JSON.parse(File.read(cache_path))
    else
      user = ENV['RTT_USER']
      password = ENV['RTT_PASSWORD']
      service_data = JSON.parse(HTTParty.get("https://#{user}:#{password}@api.rtt.io/api/v1/json/service/#{service}/#{date.strftime('%Y/%m/%d')}").body)
      File.write(cache_path, service_data.to_json)
    end
    service_data
  end
end