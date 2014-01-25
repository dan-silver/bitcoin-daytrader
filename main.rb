require 'bitstamp'
require 'colorize'

load 'fetchMarketData.rb'

Bitstamp.setup do |config|
  config.key = ENV['BITSTAMP_KEY']
  config.secret = ENV['BITSTAMP_SECRET']
  config.client_id = ENV['BITSTAMP_CLIENT_ID']
end

fetcher = FetchMarketData.new

while true do
  puts "\n"*2, "*".cyan*50, "\n"*2
  puts "Current market data:"
  puts fetcher.fetch
  puts "\n"
  puts "Change over the last 2 minutes:"
  puts fetcher.getPriceChange "-2 minutes"
  puts "Change over the last 5 minutes:"
  puts fetcher.getPriceChange "-5 minutes"
  puts "Change over the last 20 minutes:"
  puts fetcher.getPriceChange "-20 minutes"
  puts "Change over the last hour:"
  puts fetcher.getPriceChange "-1 hour"
  sleep 15
end
