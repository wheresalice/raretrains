require 'aws-sdk'

s3 = Aws::S3::Resource.new(region: 'eu-west-1')
environment = ENV['RACK_ENV'] || 'development'

LDS = Dir.glob("tmp/#{environment}/LDS-*.json")
LDS.each do |day|
  s3.bucket('leedstrains').object(File.basename(day)).upload_file(day)
end

