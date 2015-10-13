require 'json'
require 'httparty'
require 'sinatra'
require 'sinatra/flash'

require File.expand_path '../lib/helpers.rb', __FILE__

enable :sessions

helpers do
  include Helpers
  class Hash
    def dig(*path)
      path.inject(self) do |location, key|
        # Although we do get arrays, we generally only care about the first one
        location = location.is_a?(Array) ? location[0] : location
        location.respond_to?(:keys) ? location[key] : nil
      end
    end
  end

  def todays_uniques(services, *list)
    uniques = Hash.new(0)
    services.each { |service| uniques.store(service.dig(*list), uniques[service.dig(*list)] + 1) }
    return uniques
  end

  def newly_appeared(today, yesterday, *list)
    diff = today.map { |service| service.dig(*list) }.compact.sort.uniq - yesterday.map { |service| service.dig(*list) }
    diff.compact.sort.uniq.map { |d| [d, ''] }
  end

  def xss_filter(input_text)
    input_text.gsub(/[^0-9A-Za-z\ ]/, '')
  end
end

get '/' do
  erb :home,
      :layout => true
end

get '/cached' do
  response.headers['Content-Type'] = 'text/plain'
  Dir.glob("tmp/#{ENV['RACK_ENV']}/*.json").join("\n")
end

get '/unique' do
  redirect('/LDS/unique')
end

get '/:station' do
  data = load_date(params[:date], params[:station])
  services = data['services']
  tocs = todays_uniques(services, 'atocCode').sort
  origins = todays_uniques(services, 'locationDetail', 'origin', 'description').sort
  destinations = todays_uniques(services, 'locationDetail', 'destination', 'description').sort
  platforms = todays_uniques(services, 'locationDetail', 'platform')
  service_types = todays_uniques(services, 'serviceType').sort
  station = data.dig('location', 'name') || xss_filter(params[:station])
  station_code = data.dig('location', 'crs') || xss_filter(params[:station])

  erb :day, :locals => {
              :filter => '',
              :day => data['date'],
              :tocs => tocs,
              :origins => origins,
              :destinations => destinations,
              :platforms => platforms,
              :service_types => service_types,
              :station => station,
              :station_code => station_code

          },
      :layout => true
end

get '/:station/unique' do

  today_data = load_date(params[:date], params[:station])
  today_services = today_data['services']
  yesterday_services = load_date(params[:date], params[:station], true)['services']


  tocs = newly_appeared(today_services, yesterday_services, 'atocCode').sort
  origins = newly_appeared(today_services, yesterday_services, 'locationDetail', 'origin', 'description').sort
  destinations = newly_appeared(today_services, yesterday_services, 'locationDetail', 'destination', 'description').sort
  platforms = newly_appeared(today_services, yesterday_services, 'locationDetail', 'platform')
  service_types = newly_appeared(today_services, yesterday_services, 'serviceType')
  station = today_data.dig('location', 'name') || xss_filter(params[:station])
  station_code = today_data.dig('location', 'crs') || xss_filter(params[:station])

  erb :day, :locals => {
              :filter => 'new',
              :day => params[:date],
              :tocs => tocs,
              :origins => origins,
              :destinations => destinations,
              :platforms => platforms,
              :service_types => service_types,
              :station => station,
              :station_code => station_code
          },
      :layout => true
end

get '/:station/services' do
  params[:date] = nil if params[:date] == ''
  data = load_date(params[:date], params[:station])
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
  if params[:destination]
    services = services.select { |service| service.dig('locationDetail', 'destination', 'description') == params[:destination] }
    filter_string << ", to #{xss_filter(params[:destination])}"
  end
  if params[:operator]
    services = services.select { |service| service.dig('atocCode') == params[:operator] }
    filter_string << ", operated by #{xss_filter(params[:operator])}"
  end
  if params[:type]
    services = services.select { |service| service.dig('serviceType') == params[:type] }
    filter_string << ", of type #{xss_filter(params[:type])}"
  end

  erb :services, :locals => {
                   :services => services,
                   :filter => filter_string
               },
      :layout => true
end

get '/:station/platform/:platform' do
  redirect to("/#{params[:station]}/services?platform=#{params[:platform]}&date=#{params[:date]}")
end

get '/:station/from/:origin' do
  redirect to("/#{params[:station]}/services?origin=#{params[:origin]}&date=#{params[:date]}")
end

get '/:station/to/:destination' do
  redirect to("/#{params[:station]}/services?destination=#{params[:destination]}&date=#{params[:date]}")
end

get '/:station/operator/:operator' do
  redirect to("/#{params[:station]}/services?operator=#{params[:operator]}&date=#{params[:date]}")
end

get '/:station/type/:type' do
  redirect to("/#{params[:station]}/services?type=#{params[:type]}&date=#{params[:date]}")
end

get '/map/:service/:date' do
  class Tiploc
    include Comparable
    attr_accessor :latitude, :longitude, :code
    def initialize(code, lat=nil, lon=nil)
      @code = code
      @latitude = lat
      @longitude = lon
    end
    def <=> other
      @code <=> other.code
    end

    def == other
      @code == other.code
    end
  end

  service = load_service(params[:service], params[:date])
  global_tiplocs = {}
  service_tiplocs = []
  service['locations'].each {|l| service_tiplocs << Tiploc.new(l['tiploc'])}
  require 'csv'
  references = CSV.open('csv/RailReferences.csv', 'r', {:headers => true})
  references.each do |r|
    global_tiplocs[r['TiplocCode']] = Tiploc.new(r['TiplocCode'], r['Latitude'], r['Longitude'])
  end

  failed_tiplocs = 0
  enriched_tiplocs = service_tiplocs.map do |t|
    failed_tiplocs +=1 if global_tiplocs[t.code].nil?
    global_tiplocs[t.code]
  end


  erb :map, :locals => {
                   :tiplocs => enriched_tiplocs,
                   :failed_tiplocs => failed_tiplocs
               },
      :layout => true
end