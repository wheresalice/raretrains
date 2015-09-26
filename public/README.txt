# Leeds Trains

This web application started life at Leeds Hack 2015, and summarises what services are running through a given train station.

You can provide any CRS code that network rail knows about.

It caches data locally, so you may find it doesn't pick up changes to services during the day.

# Usage

To run this locally you will need to set the following environment variables

* RTT_USER
* RTT_PASSWORD

both of these are available from realtimetrains.co.uk

if you do not have an api key, then you can generate some minimal fake data for Leeds for the current day using ./bin/generate_dev_data.rb

# Contributing

You'll need ruby 2.2.something.

Install dependencies

    bundle install

Run the app

    heroku local

# Thanks

* Leeds Hack for giving me the time to work on this
* Realtime Trains for making the data available
* Glen for inspiring me to just use local files instead of MongoDB
* Those of you who've pointed out the bugs, you know who you are

# Contact

@AliceFromOnline via Twitter
