require 'bitstamp'
require 'colorize'

load 'transactionsDatabase.rb'
load '../market/marketDatabase.rb'

Bitstamp.setup do |config|
  config.key = ENV['BITSTAMP_KEY']
  config.secret = ENV['BITSTAMP_SECRET']
  config.client_id = ENV['BITSTAMP_CLIENT_ID']
end

transactionsDb = TransactionsDatabase.new
#transactionsDb.insert 0.01, 840, 0.26, :purchase
transactionsDb.insert 0.02, 870, 0.24, :sale
@marketDb = MarketDatabase.new


last_transaction = transactionsDb.all_rows.last
 puts last_transaction[0]
#             [:btc, "real"],
#              [:btc_usd, "real"],
#              [:fee, "real"],
#              [:type, "text"], #purchase/sale
#              [:timestamp, "DATETIME"]
while true do
  puts "Running main loop..."
  btc = last_transaction[0]
  type= last_transaction[3]
  if (type =='sale')
  	consider_purchase
  else
  	consider_sale
  end
  sleep 15
end
# [:btc_usd_buy, "real"],
#              [:btc_usd_sell, "real"],
#              [:timestamp, "DATETIME"]

def consider_purchase(last_sale,current_market_data)
	fee_percent = 0.5
	
	usd_avail = last_sale[0]*last_sale[1]
	usd_avail -= last_sale[2]

	last_bitcoin_market_value = last_transaction[1]
	current_bitcoin_market_value = current_market_data[0]

	percent_increase = (current_market_data-last_bitcoin_market_value)/last_bitcoin_market_value


end

def 

def consider_sale
end

def purchase_costs
end

def sale_costs
end