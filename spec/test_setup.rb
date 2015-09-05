ENV['RACK_ENV'] = 'test'
ENV['TMP'] = 'spec/data'
require 'json'
require 'minitest/autorun'
require 'rack/test'
require 'fileutils'
require File.expand_path '../../findinteresting.rb', __FILE__

# Clean out test tmp directory
Dir.glob(File.expand_path '../../tmp/test/*.json', __FILE__).each { |f| File.unlink f }

# Generate known data
departure_data = {'services' => [
    {"locationDetail" =>
         {"realtimeActivated" => true,
          "tiploc" => "LEEDS",
          "crs" => "LDS",
          "description" => "Leeds",
          "gbttBookedArrival" => "0044",
          "gbttBookedArrivalNextDay" => true,
          "gbttBookedDeparture" => "0047",
          "gbttBookedDepartureNextDay" => true,
          "origin" =>
              [{"tiploc" => "MNCRPIC",
                "description" => "Manchester Piccadilly",
                "workingTime" => "233500",
                "publicTime" => "2335"}],
          "destination" =>
              [{"tiploc" => "YORK",
                "description" => "York",
                "workingTime" => "012700",
                "publicTime" => "0129"}],
          "isCall" => true,
          "isPublicCall" => true,
          "realtimeArrival" => "0043",
          "realtimeArrivalActual" => true,
          "realtimeArrivalNextDay" => true,
          "realtimeDeparture" => "0047",
          "realtimeDepartureActual" => true,
          "realtimeDepartureNextDay" => true,
          "platform" => "9",
          "platformConfirmed" => true,
          "platformChanged" => false,
          "displayAs" => "CALL"},
     "serviceUid" => "Y00118",
     "runDate" => "2015-08-28",
     "trainIdentity" => "1P68",
     "runningIdentity" => "1P68",
     "atocCode" => "TP",
     "atocName" => "First Transpennine Express",
     "serviceType" => "train",
     "isPassenger" => true,
     "origin" =>
         [{"tiploc" => "MNCRIAP",
           "description" => "Manchester Airport",
           "workingTime" => "232000",
           "publicTime" => "2320"}],
     "destination" =>
         [{"tiploc" => "YORK",
           "description" => "York",
           "workingTime" => "012700",
           "publicTime" => "0129"}]}]}

arrival_data = {'services' => [{"locationDetail" =>
                                    {"realtimeActivated" => true,
                                     "tiploc" => "LEEDS",
                                     "crs" => "LDS",
                                     "description" => "Leeds",
                                     "gbttBookedArrival" => "0031",
                                     "gbttBookedArrivalNextDay" => true,
                                     "gbttBookedDeparture" => "0034",
                                     "gbttBookedDepartureNextDay" => true,
                                     "origin" =>
                                         [{"tiploc" => "LVRPLSH",
                                           "description" => "Liverpool Lime Street",
                                           "workingTime" => "223000",
                                           "publicTime" => "2230"}],
                                     "destination" =>
                                         [{"tiploc" => "YORK",
                                           "description" => "York",
                                           "workingTime" => "011100",
                                           "publicTime" => "0113"}],
                                     "isCall" => true,
                                     "isPublicCall" => true,
                                     "realtimeArrival" => "0031",
                                     "realtimeArrivalActual" => true,
                                     "realtimeArrivalNextDay" => true,
                                     "realtimeDeparture" => "0034",
                                     "realtimeDepartureActual" => true,
                                     "realtimeDepartureNextDay" => true,
                                     "platform" => "8",
                                     "platformConfirmed" => true,
                                     "platformChanged" => false,
                                     "displayAs" => "CALL"},
                                "serviceUid" => "Y00244",
                                "runDate" => "2015-08-28",
                                "trainIdentity" => "1E96",
                                "runningIdentity" => "1E96",
                                "atocCode" => "TP",
                                "atocName" => "First Transpennine Express",
                                "serviceType" => "train",
                                "isPassenger" => true}]}

no_trains = {"location" => {
    "name" => "Kirton Lindsey",
    "crs" => "KTL",
    "tiploc" => "KRTNLND"},
             "filter" => nil,
             "services" => nil
}

FileUtils.mkdir_p(File.expand_path('../../tmp/test', __FILE__))
File.write(File.expand_path('../../tmp/test/LDS-departures-2015-08-29.json', __FILE__), departure_data.to_json)
File.write(File.expand_path('../../tmp/test/LDS-arrivals-2015-08-29.json', __FILE__), arrival_data.to_json)
File.write(File.expand_path('../../tmp/test/LDS-departures-2015-08-28.json', __FILE__), departure_data.to_json)
File.write(File.expand_path('../../tmp/test/LDS-arrivals-2015-08-28.json', __FILE__), arrival_data.to_json)

File.write(File.expand_path('../../tmp/test/KTL-departures-2015-08-29.json', __FILE__), no_trains.to_json)
File.write(File.expand_path('../../tmp/test/KTL-arrivals-2015-08-29.json', __FILE__), no_trains.to_json)
File.write(File.expand_path('../../tmp/test/KTL-departures-2015-08-28.json', __FILE__), no_trains.to_json)
File.write(File.expand_path('../../tmp/test/KTL-arrivals-2015-08-28.json', __FILE__), no_trains.to_json)
