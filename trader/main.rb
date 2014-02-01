require 'colorize'
require 'bitstamp'

load 'trader.rb'
load 'traderStats.rb'
load 'transactionsDatabase.rb'
load 'marketDatabase.rb'
load 'marketData.rb'
load '../general_library.rb'

Bitstamp.setup do |config|
  config.key = ENV["BITSTAMP_KEY"]
  config.secret = ENV["BITSTAMP_SECRET"]
  config.client_id = ENV["BITSTAMP_CLIENT_ID"]
end

transactionsDb       = TransactionsDatabase.new
marketDb             = MarketDatabase.new
traderStats          = TraderStats.new marketDb
marketDataFetcher    = MarketData.new marketDb
marketDataAggregator = MarketDataAggregator.new

trader = Trader.new do |t|
  t.min_percent_gain = 0.012
  t.min_percent_drop = -0.01
  t.transactionsDb = transactionsDb
  t.marketDb = marketDb
  t.stats = traderStats
end

#this aggregator stuff might desperately need to get out of this module
aggregator = MarketDataAggregator.new
sample_rows = marketDb.last_rows 1000
sample_rows.each do |row|
  marketDataAggregator.place_data_point aggregator.assemble_data_point_from_row row 
end


# puts marketDataAggregator.most_recent_data_point.buy_value_in_usd

#marketDataAggregator.report 2*minute, halfhour
#jitter = marketDataAggregator.get_jitter_since_seconds_ago halfhour
#puts jitter
#deltas = marketDataAggregator.get_deltas_since_seconds_ago 30.minutes
#puts deltas

while true do
  marketDataFetcher.fetch
  puts format_stars
  trader.trade
  
  latest_row = marketDb.last_row #dear god this needs to be rethought
  row_data_point = marketDataAggregator.assemble_data_point_from_row latest_row
  marketDataAggregator.place_data_point row_data_point
  puts (marketDataAggregator.get_jitter_since_seconds_ago 30.minutes).first
  sleep 5.seconds
end