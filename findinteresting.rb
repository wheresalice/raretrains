require 'json'
require 'httparty'
require 'sinatra'
require File.expand_path '../lib/helpers.rb', __FILE__

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

  def todays_uniques(*list)
    uniques = Hash.new(0)
    @current_day_services.each { |service| uniques.store(service.dig(*list), uniques[service.dig(*list)] + 1) }
    return uniques
  end

  def previous_uniques(*list)
    uniques = Hash.new(0)
    @previous_day_services.each { |service| uniques.store(service.dig(*list), uniques[service.dig(*list)] + 1) }
    return uniques
  end

  def newly_appeared(*list)
    diff = @current_day_services.map {|service| service.dig(*list)}.compact.sort.uniq - @previous_day_services.map {|service| service.dig(*list)}
    diff.compact.sort.uniq.map{|d| [d, '']}
  end
end

get '/' do
  redirect('/LDS')
end

get '/cached' do
  response.headers['Content-Type'] = 'text/plain'
  Dir.glob("tmp/#{ENV['RACK_ENV']}/*.json").join("\n")
end

get '/unique' do
  redirect('/LDS/unique')
end

get '/:station' do
  date = load_date(params[:date], params[:station])

  tocs = todays_uniques('atocCode').sort
  origins = todays_uniques('locationDetail','origin','description').sort
  destinations = todays_uniques('locationDetail','destination','description').sort
  platforms = todays_uniques('locationDetail','platform')

  erb :day, :locals => {
              :filter => 'distinct',
              :day => date,
              :tocs => tocs,
              :origins => origins,
              :destinations => destinations,
              :platforms => platforms,
              :station => params[:station].gsub(/[^0-9A-Za-z\ ]/, '')
          },
      :layout => true
end

get '/:station/unique' do
  date = load_date(params[:date], params[:station])


  tocs = newly_appeared('atocCode').sort
  origins = newly_appeared('locationDetail','origin','description').sort
  destinations = newly_appeared('locationDetail','destination','description').sort
  platforms = newly_appeared('locationDetail','platform')

  erb :day, :locals => {
              :filter => 'new',
              :day => date,
              :tocs => tocs,
              :origins => origins,
              :destinations => destinations,
              :platforms => platforms,
              :station => params[:station].gsub(/[^0-9A-Za-z\ ]/, '')
          },
      :layout => true
end

get '/:station/platform/:platform' do
  date = load_date(params[:date], params[:station])
  services = @current_day_services.select { |service| service.dig('locationDetail', 'platform') == params['platform'] }
  erb :services, :locals => {
                   :services => services,
                   :filter => "using #{params[:station].gsub(/[^0-9A-Za-z\ ]/, '')} platform #{params['platform'].gsub(/[^0-9A-Za-z\ ]/, '')} for #{date}"
               },
      :layout => true
end

get '/:station/from/:origin' do
  date = load_date(params[:date], params[:station])
  services = @current_day_services.select { |service| service.dig('locationDetail', 'origin', 'description') == params['origin'] }
  erb :services, :locals => {
                   :services => services,
                   :filter => "from #{params['origin'].gsub(/[^0-9A-Za-z\ ]/, '')} via #{params[:station].gsub(/[^0-9A-Za-z\ ]/, '')} for #{date}"
               },
      :layout => true
end

get '/:station/to/:destination' do
  date = load_date(params[:date], params[:station])
  services = @current_day_services.select { |service| service.dig('locationDetail', 'destination', 'description') == params['destination'] }
  erb :services, :locals => {
                   :services => services,
                   :filter => "to #{params['destination'].gsub(/[^0-9A-Za-z\ ]/, '')} via #{params[:station].gsub(/[^0-9A-Za-z\ ]/, '')} for #{date}"
               },
      :layout => true
end

get '/:station/operator/:operator' do
  date = load_date(params[:date], params[:station])
  services = @current_day_services.select { |service| service.dig('atocCode') == params['operator'] }
  erb :services, :locals => {
                   :services => services,
                   :filter => "run by #{params[:operator].gsub(/[^0-9A-Za-z\ ]/, '')} from #{params[:station].gsub(/[^0-9A-Za-z\ ]/, '')} for #{date}"
               },
      :layout => true
end
