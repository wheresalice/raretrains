require 'json'
require 'httparty'
module Helpers
  def get_rtt_workings(date = Date.today, station = 'LDS', mode='departures')
    station = station.upcase.gsub(/[^0-9A-Z\ ]/, '')
    tmp_dir = File.join('tmp', ENV['RACK_ENV'])

    Dir.mkdir(tmp_dir) unless File.directory?(tmp_dir)
    cache_path = File.join(tmp_dir, "#{station}-#{mode}-#{date.strftime("%Y-%m-%d")}.json")
    if File.exist? cache_path
      puts "already got data for #{station} #{mode} for #{date}"
      results = JSON.parse(File.read(cache_path))
    else
      return {'date' => date.strftime('%Y-%m-%d'), 'services' => []} if ENV['RACK_ENV'] == 'test'
      puts "getting data for #{station} #{mode} for #{date}"
      user = ENV['RTT_USER']
      password = ENV['RTT_PASSWORD']
      begin
        response = HTTParty.get("http://#{user}:#{password}@api.rtt.io/api/v1/json/search/#{station}/#{date.strftime("%Y/%m/%d")}#{'/arrivals' if mode == 'arrivals'}")
        results = JSON.parse(response.body)
        results['date'] = date
        results['station'] = station
        results['mode'] = mode
        results['_id'] = "#{station}-#{mode}-#{date.strftime("%Y-%m-%d")}"
        results['services'] = results['services'].to_a
        File.write(cache_path, results.to_json)
        flash.now['bg-info'] = 'Downloaded new data' if (defined? flash)
        if results['error']
          flash.now['bg-danger'] = results['error'] if (defined? flash)
        end
      rescue => e
        puts e
        flash.now['bg-danger'] = e if (defined? flash)
        results = {'services' => []}
      end
    end
    return results
  end

  def clean_tmp
    Dir.glob("tmp/#{ENV['RACK_ENV']}/*json").each {|f| File.unlink(f) if File.stat(f).mtime < Time.now - 60*60*24*8 }
    puts 'cleaning tmp'
  end

  def merge_services(departures, arrivals)
    departures_hash = ::Hash[departures.map{|h| [h['serviceUid'], h]}]
    arrivals_hash = ::Hash[arrivals.map{|h| [h['serviceUid'], h]}]
    return departures_hash.merge(arrivals_hash).values
  end

  def load_date(date=Date.today.to_s, station='LDS', yesterday=false)
    date = date.nil? ? Date.today : Date.parse(date)
    date = date - 1 if yesterday

    workings = get_rtt_workings(date, station.upcase, 'departures')
    arrival_workings = get_rtt_workings(date, station.upcase, 'arrivals')

    services = workings['services']
    arrivals = arrival_workings['services']
    clean_tmp
    merged_services = merge_services(services, arrivals)
    workings['services'] = merged_services
    return workings
  end

end