require 'bitstamp'
require 'colorize'

load 'transactionsDatabase.rb'
load 'marketDatabase.rb'

class Trader
  def initialize(options)
    @min_percent_gain = options[:percent_gain_for_sale]
    @min_percent_drop = options[:percent_change_for_purchase]

    Bitstamp.setup do |config|
      config.key = ENV["BITSTAMP_KEY"]
      config.secret = ENV["BITSTAMP_SECRET"]
      config.client_id = ENV["BITSTAMP_CLIENT_ID"]
    end
    @transactionsDb = TransactionsDatabase.new
    @transactionsDb.insert 0.01, 740, 0.26, :purchase
    #@transactionsDb.insert 0.02, 900, 0.09, :sale

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
    type = last_transaction[:type]
    type == "sale" ? consider_purchase(last_transaction) : consider_sale(last_transaction)

  end
  # [:btc_usd_buy, "real"],
  #              [:btc_usd_sell, "real"],
  #              [:timestamp, "DATETIME"]

  def consider_purchase(last_sale)
    puts "consider_purchase!!!"
    
    #fee_percent = 0.5
    current_market_data = @marketDb.all_rows.last

    usd_avail = last_sale[:btc]*last_sale[:btc_usd]

    last_bitcoin_market_value = last_sale[:btc_usd]
    current_bitcoin_market_value = current_market_data[:btc_usd_buy]

    percent_change = (current_bitcoin_market_value-last_bitcoin_market_value)/last_bitcoin_market_value
    puts percent_change
    if percent_change < @min_percent_drop
      puts "Minimum purchase threshold reached"
      purchase current_bitcoin_market_value, usd_avail
    end
  end

  def purchase(btc_usd, usd_avail)
    puts "Purchasing"

    fee = usd_avail * 0.005
    usd_avail -= fee
    btc_quantity = usd_avail / btc_usd
    @transactionsDb.insert btc_quantity, btc_usd, fee, :purchase
    #Bitstamp.orders.buy(amount: 1.0, price: 111)
  end

  def consider_sale(last_purchase)
    puts last_purchase
    puts "Considering a sale"

    current_market_data = @marketDb.all_rows.last

    #usd_value_of_bitcoins_owned = last_purchase[:btc]*last_purchase[:btc_usd]
    #usd_value_of_bitcoins_owned -= last_purchase[:fee]

    last_bitcoin_market_value = last_purchase[:btc_usd]
    
    current_bitcoin_market_value = current_market_data[:btc_usd_buy]
    percent_change = (current_bitcoin_market_value-last_bitcoin_market_value)/last_bitcoin_market_value

    if percent_change > @min_percent_gain
      puts "Minimum sale threshold reached"
      sell current_bitcoin_market_value, last_purchase[:btc]
    end
    puts percent_change
  end

  def sell (btc_usd, btc_quantity)
    puts "Selling"
    fee = btc_usd * btc_quantity * 0.005
    @transactionsDb.insert btc_quantity, btc_usd, fee, :sale
    #Bitstamp.orders.sell(amount: 1.0, price: 111)
  end

  '''
  def purchase_costs
  end

  def sale_costs
  end
  '''
end

trader = Trader.new :percent_gain_for_sale => 0.01, :percent_change_for_purchase => -0.01
while true do
  puts "Running main loop..."
  trader.trade
  sleep 10
end
