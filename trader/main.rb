require 'bitstamp'
require 'colorize'

load 'transactionsDatabase.rb'

Bitstamp.setup do |config|
  config.key = ENV['BITSTAMP_KEY']
  config.secret = ENV['BITSTAMP_SECRET']
  config.client_id = ENV['BITSTAMP_CLIENT_ID']
end


while true do
  puts "Running main loop..."
  sleep 15
end
