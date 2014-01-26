require 'bitstamp'
require 'colorize'

load 'transactionsDatabase.rb'
load '../market/marketDatabase.rb'

class Trader
  def initialize
    Bitstamp.setup do |config|
      config.key = ENV["BITSTAMP_KEY"]
      config.secret = ENV["BITSTAMP_SECRET"]
      config.client_id = ENV["BITSTAMP_CLIENT_ID"]
    end
    @transactionsDb = TransactionsDatabase.new
    #transactionsDb.insert 0.01, 840, 0.26, :purchase
    @transactionsDb.insert 0.02, 870, 0.24, :sale

    @marketDb = MarketDatabase.new
  end


 #  puts last_transaction[0]
  #             [:btc, "real"],
  #              [:btc_usd, "real"],
  #              [:fee, "real"],
  #              [:type, "text"], #purchase/sale
  #              [:timestamp, "DATETIME"]
  def trade
    puts "trading!"

    last_transaction = @transactionsDb.all_rows.last
    type = last_transaction[3]
    type == "sale" ? consider_purchase(last_transaction) : consider_sale

  end
  # [:btc_usd_buy, "real"],
  #              [:btc_usd_sell, "real"],
  #              [:timestamp, "DATETIME"]

  def consider_purchase(last_sale)
    puts last_sale
    puts "consider_purchase!!!"
    
    #fee_percent = 0.5
    current_market_data = @marketDb.all_rows.last

    usd_avail = last_sale[0]*last_sale[1]
    usd_avail -= last_sale[2]

    last_bitcoin_market_value = last_sale[1]
    current_bitcoin_market_value = current_market_data[0]

    percent_increase = (current_bitcoin_market_value-last_bitcoin_market_value)/last_bitcoin_market_value
    puts percent_increase
  end

  def consider_sale
  end

  '''
  def purchase_costs
  end

  def sale_costs
  end
  '''
end

trader = Trader.new
while true do
  puts "Running main loop..."
  trader.trade
  sleep 10
end
