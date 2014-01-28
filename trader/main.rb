require 'bitstamp'
require 'colorize'

load 'transactionsDatabase.rb'
load 'marketDatabase.rb'
load '../rounding.rb'

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
    @marketDb = MarketDatabase.new

    #@transactionsDb.insert 0.25, 745, 1.86, :purchase
    @transactionsDb.insert 0.25, 772, 0.97, :sale

    @profit_this_run = 0 #not nil since it really is zero at this point
    #@current_market_data = nil
  end

  def trade
    last_transaction = @transactionsDb.last
    @current_market_data = @marketDb.last_row

    puts "Last Transaction:".green
    puts last_transaction, ""
    last_transaction[:type] == :sale ? consider_purchase : consider_sale
    puts "profit this run "+"#{@profit_this_run}".cyan
  end

  def consider_purchase
    last_sale = @transactionsDb.last :sale
    puts "Considering a purchase".green

    usd_avail = last_sale[:btc] * last_sale[:btc_usd]

    last_bitcoin_market_value = last_sale[:btc_usd]
    current_bitcoin_market_value = @current_market_data[:btc_usd_buy]

    percent_change = (current_bitcoin_market_value-last_bitcoin_market_value)/last_bitcoin_market_value
    
    puts "Current bitcoin price: $#{@current_market_data[:btc_usd_buy].usd_round}"
    puts "Waiting for a drop of #{@min_percent_drop*100}%"
    puts "Percent change in bitcoin conversion value: " + "#{((percent_change*100).percent_round.to_s+"%").color_by_sign}"
    printPriceChanges
    if percent_change < @min_percent_drop
      puts "Minimum purchase threshold reached"
      purchase current_bitcoin_market_value, usd_avail
    end
  end

  def printPriceChanges
    times = ["1 minute", "2 minutes", "5 minutes", "20 minutes", "45 minutes"]
    puts "Change over the last:"
    times.each do |time|
      puts "\t#{time}: #{getPriceChange(time)[:buy].usd_round.to_s.dollar_sign.color_by_sign}"
    end
  end

  def purchase(btc_usd, usd_avail)
    puts "Purchasing!".light_green

    fee = usd_avail * 0.005
    usd_avail -= fee
    btc_quantity = usd_avail / btc_usd
    @transactionsDb.insert btc_quantity, btc_usd, fee, :purchase
    #Bitstamp.orders.buy(amount: 1.0, price: 111)
  end

  def consider_sale
    puts "Considering a sale".green
    last_purchase = @transactionsDb.last :purchase

    last_bitcoin_market_value = last_purchase[:btc_usd]
    
    current_bitcoin_market_value = @current_market_data[:btc_usd_sell]
    percent_change = (current_bitcoin_market_value-last_bitcoin_market_value)/last_bitcoin_market_value
    printPriceChanges
    if percent_change > @min_percent_gain
      puts "Minimum sale threshold reached"
      sell current_bitcoin_market_value, last_purchase[:btc]
    end
    puts "Current bitcoin price: $#{@current_market_data[:btc_usd_sell].usd_round}"
    puts "Waiting for a gain of #{@min_percent_gain*100}%"
    puts "Percent change in bitcoin conversion value: " + "#{(percent_change*100).percent_round.color_by_sign}%"
  end

  def sell (btc_usd, btc_quantity)
    puts "Selling!".light_green
    fee = btc_usd * btc_quantity * 0.005
    begin
      #Bitstamp.orders.sell(amount: 1.0, price: 111)
    rescue Exception => e
      puts "error making transaction"      
    end
    transaction_success = false
    while !transaction_success
      begin
        @transactionsDb.insert btc_quantity, btc_usd, fee, :sale
        transaction_success = true
        update_profit btc_usd, btc_quantity
      rescue Exception => e
        puts "failure recording transaction, retrying",e
        transaction_success = false
        sleep 1
      end
    end
  end

  def update_profit(btc_usd_current, btc_quantity)
    previous_purchase = @transactionsDb.last :purchase
    btc_usd_old = previous_purchase[:btc_usd]
    btc_quantity_old = previous_purchase[:btc]
    #we just cashed out $ - we purchased last with $
    money_made = btc_usd_current*btc_quantity-btc_usd_old*btc_quantity_old
    @profit_this_run += money_made
    @profit_this_run = @profit_this_run.usd_round
  end

  def getPriceChange(timechange)
    return if @current_market_data == nil
    res = @marketDb.convert_to_keys @marketDb.execute("select * from market where timestamp > datetime('now', 'localtime', '-#{timechange}') order by timestamp asc limit 1;").first
    {:buy => @current_market_data[:btc_usd_buy] - res[:btc_usd_buy], :sell => @current_market_data[:btc_usd_sell] - res[:btc_usd_sell]}
  end

end

trader = Trader.new :percent_gain_for_sale => 0.02, :percent_change_for_purchase => -0.01
while true do
  puts "",("*"*50).cyan,""
  trader.trade

  sleep 5
end