require 'bitstamp'

load 'fetchMarketData.rb'

Bitstamp.setup do |config|
  config.key = ENV['BITSTAMP_KEY']
  config.secret = ENV['BITSTAMP_SECRET']
  config.client_id = ENV['BITSTAMP_CLIENT_ID']
end

fetcher = FetchMarketData.new

while true do
  p "Fetching market data"
  fetcher.fetch
  sleep 15
end
