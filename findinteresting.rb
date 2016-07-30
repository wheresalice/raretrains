require 'sinatra'
require 'date'

require File.expand_path '../lib/rare_trains.rb', __FILE__
require File.expand_path '../lib/service.rb', __FILE__
require File.expand_path '../lib/time_table.rb', __FILE__
require File.expand_path '../lib/tiploc.rb', __FILE__

before do
  headers "Content-Security-Policy-Report-Only" => "default-src 'self' 'unsafe-inline' https://api.mapbox.com:443; connect-src *.tiles.mapbox.com; img-src 'self' *.tiles.mapbox.com api.mapbox.com data:; report-uri https://leedstrains.report-uri.io/r/default/csp/reportOnly"
  headers "X-Frame-Options" => "DENY"
  headers "X-Xss-Protection" => "1; mode=block"
end

get '/' do
  erb :home,
      layout: true
end

post '/' do
  station = xss_filter(params[:station])
  station = 'LDS' if station.empty?
  date = xss_filter(params[:date])
  if params[:unique] == 'on'
    unique = true
  else
    unique = false
  end
  redirect "/#{station}?date=#{date}" unless unique
  redirect "/#{station}/unique?date=#{date}" if unique
end

get '/cached' do
  response.headers['Content-Type'] = 'text/plain'
  Dir.glob("tmp/#{ENV['RACK_ENV']}/*.json").join("\n")
end

get '/:station' do
  station = xss_filter(params[:station])
  date = parse_date(params[:date])
  data = TimeTable.new(date, station)

  tocs = data.unique_with_count('atocCode')
  origins = data.unique_with_count('locationDetail', 'origin', 'description')
  destinations = data.unique_with_count('locationDetail', 'destination', 'description')
  platforms = data.unique_with_count('locationDetail', 'platform')
  service_types = data.unique_with_count('serviceType')
  station = data.dig('location', 'name') || station
  station_code = data.code

  erb :day, locals: {
      filter: '',
      day: date,
      tocs: tocs,
      origins: origins,
      destinations: destinations,
      platforms: platforms,
      service_types: service_types,
      station: station,
      station_code: station_code

  },
      layout: true
end

get '/:station/unique' do
  station = xss_filter(params[:station])
  date = parse_date(params[:date])
  todays_data = TimeTable.new(date, station)
  today_services = todays_data['services']
  yesterdays_data = TimeTable.new(date.prev_day, station)
  yesterday_services = yesterdays_data['services']

  tocs = newly_appeared(today_services, yesterday_services, 'atocCode').sort
  origins = newly_appeared(today_services, yesterday_services, 'locationDetail', 'origin', 'description').sort
  destinations = newly_appeared(today_services, yesterday_services, 'locationDetail', 'destination', 'description').sort
  platforms = newly_appeared(today_services, yesterday_services, 'locationDetail', 'platform')
  service_types = newly_appeared(today_services, yesterday_services, 'serviceType')
  station = todays_data.dig('location', 'name') || xss_filter(params[:station])
  station_code = todays_data.code

  erb :day, locals: {
      filter: 'new',
      day: date,
      tocs: tocs,
      origins: origins,
      destinations: destinations,
      platforms: platforms,
      service_types: service_types,
      station: station,
      station_code: station_code
  },
      layout: true
end

get '/:station/services' do
  station = xss_filter(params[:station])
  date = parse_date(params[:date])
  data = TimeTable.new(date, station)

  filter_string = "for #{data.dig('location', 'name')}"
  services = data['services']
  if params[:platform]
    services = services.select { |service| service.dig('locationDetail', 'platform') == params[:platform] }
    filter_string << ", platform #{xss_filter(params[:platform])}"
  end
  if params[:origin]
    services = services.select { |service| service.dig('locationDetail', 'origin', 'description') == params[:origin] }
    filter_string << ", from #{xss_filter(params[:origin])}"
  end
  if params[:from]
    services = services.select { |service| service.dig('locationDetail', 'origin', 'description') == params[:from] }
    filter_string << ", from #{xss_filter(params[:from])}"
  end
  if params[:destination]
    services = services.select { |service| service.dig('locationDetail', 'destination', 'description') == params[:destination] }
    filter_string << ", to #{xss_filter(params[:destination])}"
  end
  if params[:to]
    services = services.select { |service| service.dig('locationDetail', 'destination', 'description') == params[:to] }
    filter_string << ", to #{xss_filter(params[:to])}"
  end
  if params[:operator]
    services = services.select { |service| service.dig('atocCode') == params[:operator] }
    filter_string << ", operated by #{xss_filter(params[:operator])}"
  end
  if params[:type]
    services = services.select { |service| service.dig('serviceType') == params[:type] }
    filter_string << ", of type #{xss_filter(params[:type])}"
  end

  erb :services, locals: {
      services: services,
      filter: filter_string
  },
      layout: true
end

get '/map/:service/:date' do
  date = Date.parse(xss_filter(params[:date]))
  service = xss_filter(params[:service])
  service_data = Service.new(service, date)
  global_tiplocs = {}
  service_tiplocs = []
  Array(service_data['locations']).each { |l| service_tiplocs << Tiploc.new(l['tiploc']) }
  require 'csv'
  references = CSV.open('csv/RailReferences.csv', 'r', {headers: true})
  references.each do |r|
    global_tiplocs[r['TiplocCode']] = Tiploc.new(r['TiplocCode'], r['Latitude'], r['Longitude'])
  end

  failed_tiplocs = 0
  enriched_tiplocs = service_tiplocs.map do |t|
    failed_tiplocs += 1 if global_tiplocs[t.code].nil?
    global_tiplocs[t.code]
  end

  erb :map, locals: {
      tiplocs: enriched_tiplocs,
      failed_tiplocs: failed_tiplocs
  },
      layout: true
end