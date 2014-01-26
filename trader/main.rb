require 'bitstamp'
require 'colorize'

load 'transactionsDatabase.rb'

Bitstamp.setup do |config|
  config.key = ENV['BITSTAMP_KEY']
  config.secret = ENV['BITSTAMP_SECRET']
  config.client_id = ENV['BITSTAMP_CLIENT_ID']
end

transactionsDb = TransactionsDatabase.new
#transactionsDb.insert 0.01, 840, 0.26, :purchase
#transactionsDb.insert 0.01, 870, 0.24, :sale

while true do
  puts "Running main loop..."
  sleep 15
end
