require 'colorize'
require 'bitstamp'

load 'trader.rb'
load 'traderStats.rb'
load 'transactionsDatabase.rb'
load 'marketDatabase.rb'
load 'marketDataPoint.rb'
load 'marketDataAggregator.rb'
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
aggregator = MarketDataAggregator.new

trader = Trader.new do |t|
  t.min_percent_gain = 0.012
  t.min_percent_drop = -0.01
  t.transactionsDb = transactionsDb
  t.marketDb = marketDb
  t.stats = traderStats
end

aggregator.place_data_points marketDb.last_rows 1000

'''
#puts marketDataAggregator.most_recent_data_point

#marketDataAggregator.report 2.minutes, 30.minutes
#jitter = marketDataAggregator.get_jitter_since_seconds_ago 30.minutes
#puts jitter
deltas = aggregator.get_deltas_since 30.minutes
puts deltas
'''

while true do
  marketDataFetcher.fetch
  puts format_stars
  #trader.trade

  latest_row = marketDb.last_row #dear god this needs to be rethought
  row_data_point = aggregator.assemble_data_point_from_row latest_row
  aggregator.place_data_point row_data_point
  puts (aggregator.get_confidence_points_since 100.seconds)

  sleep 5.seconds
end