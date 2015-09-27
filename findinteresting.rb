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
  station = data.dig('location', 'name') || params[:station].gsub(/[^0-9A-Za-z\ ]/, '')
  station_code = data.dig('location', 'crs') || params[:station].gsub(/[^0-9A-Za-z\ ]/, '')


  erb :day, :locals => {
              :filter => '',
              :day => data['date'],
              :tocs => tocs,
              :origins => origins,
              :destinations => destinations,
              :platforms => platforms,
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
  station = today_data.dig('location', 'name') || today_data.gsub(/[^0-9A-Za-z\ ]/, '')
  station_code = today_data.dig('location', 'crs') || params[:station].gsub(/[^0-9A-Za-z\ ]/, '')

  erb :day, :locals => {
              :filter => 'new',
              :day => params[:date],
              :tocs => tocs,
              :origins => origins,
              :destinations => destinations,
              :platforms => platforms,
              :station => station,
              :station_code => station_code
          },
      :layout => true
end

get '/:station/platform/:platform' do
  data = load_date(params[:date], params[:station])
  services = data['services'].select { |service| service.dig('locationDetail', 'platform') == params['platform'] }
  erb :services, :locals => {
                   :services => services,
                   :filter => "using #{params[:station].gsub(/[^0-9A-Za-z\ ]/, '')} platform #{params['platform'].gsub(/[^0-9A-Za-z\ ]/, '')} for #{data['date']}"
               },
      :layout => true
end

get '/:station/from/:origin' do
  data = load_date(params[:date], params[:station])
  services = data['services'].select { |service| service.dig('locationDetail', 'origin', 'description') == params['origin'] }
  erb :services, :locals => {
                   :services => services,
                   :filter => "from #{params['origin'].gsub(/[^0-9A-Za-z\ ]/, '')} via #{params[:station].gsub(/[^0-9A-Za-z\ ]/, '')} for #{data['date']}"
               },
      :layout => true
end

get '/:station/to/:destination' do
  data = load_date(params[:date], params[:station])
  services = data['services'].select { |service| service.dig('locationDetail', 'destination', 'description') == params['destination'] }
  erb :services, :locals => {
                   :services => services,
                   :filter => "to #{params['destination'].gsub(/[^0-9A-Za-z\ ]/, '')} via #{params[:station].gsub(/[^0-9A-Za-z\ ]/, '')} for #{data['date']}"
               },
      :layout => true
end

get '/:station/operator/:operator' do
  data = load_date(params[:date], params[:station])
  services = data['services'].select { |service| service.dig('atocCode') == params['operator'] }
  erb :services, :locals => {
                   :services => services,
                   :filter => "run by #{params[:operator].gsub(/[^0-9A-Za-z\ ]/, '')} from #{params[:station].gsub(/[^0-9A-Za-z\ ]/, '')} for #{data['data']}"
               },
      :layout => true
end
