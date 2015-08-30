# Leeds Trains

This web application started life at Leeds Hack 2015, and summarises what services are running through a given train station.  It defaults to LDS, but can run for any station with a CRS code.

It caches data locally, so you may find it doesn't pick up changes to services during the day.

The source code for this site is available on request - it's pretty ugly as it was built for a hack day.  If you're interested, it's written in ruby/Sinatra.

# Changelog

* 2015-08-30 Make tables sortable
* 2015-08-29 Handle spaces in station names, accept arbitrary dates for testing, accept arbitrary stations, handle arrivals
* 2015-08-23 Fixed caching so it actually pulls in data for new days and wrote this README

# TODO

* Handle changes during the day

# Thanks

* Leeds Hack for giving me the time to work on this
* Realtime Trains for making the data available
* Glen for inspiring me to just use local files instead of MongoDB
* Those of you who've pointed out the bugs, you know who you are

# Contact

@AliceFromOnline via Twitter
