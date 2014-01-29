require 'bitstamp'
require 'colorize'

load 'transactionsDatabase.rb'
load 'marketDatabase.rb'
load '../rounding.rb'
load 'traderStats.rb'
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
    @stats = TraderStats.new( @transactionsDb, @marketDb)
    @fee = nil

    @transactionsDb.insert 0.235, 795, 0.90, :purchase
    #@transactionsDb.insert 0.25, 772, 0.97, :sale

    #@current_market_data = nil
    refresh_fee
  end

  def refresh_fee
    @fee = Bitstamp.balance["fee"].to_f * 0.01
    puts "Current fee is #{@fee*100}%".light_cyan
  end

  def trade
    last_transaction = @transactionsDb.last
    @current_market_data = @marketDb.last_row

    puts "Last Transaction:".green
    puts last_transaction, ""
    last_transaction[:type] == :sale ? consider_purchase : consider_sale
  end

  def consider_purchase
    last_sale = @transactionsDb.last :sale
    puts "Considering a purchase".green

    usd_avail = last_sale[:btc] * last_sale[:btc_usd] - last_sale[:fee]

    last_bitcoin_market_value = last_sale[:btc_usd]
    current_bitcoin_market_value = @current_market_data[:btc_usd_buy]

    btc_percent_change = percent_change current_bitcoin_market_value, last_bitcoin_market_value
    
    puts "Current bitcoin price: $#{@current_market_data[:btc_usd_buy].usd_round}"
    puts "Waiting for a drop of #{@min_percent_drop*100}%"
    puts "Percent change in bitcoin conversion value: " + "#{((btc_percent_change*100).percent_round.to_s+"%").color_by_sign}"
    @stats.printPriceChanges :buy
    if btc_percent_change < @min_percent_drop
      puts "Minimum purchase threshold reached"
      purchase current_bitcoin_market_value, usd_avail
    end
  end

  def purchase(btc_usd, usd_avail)
    puts "Purchasing!".light_green

    fee = usd_avail * @fee
    usd_avail -= fee
    btc_quantity = usd_avail / btc_usd
    @transactionsDb.insert btc_quantity, btc_usd, fee, :purchase
    #Bitstamp.orders.buy(amount: 1.0, price: 111)
    refresh_fee
  end

  def consider_sale
    puts "Considering a sale".green
    last_purchase = @transactionsDb.last :purchase

    last_bitcoin_market_value = last_purchase[:btc_usd]

    current_bitcoin_market_value = @current_market_data[:btc_usd_sell]
    btc_percent_change = percent_change current_bitcoin_market_value, last_bitcoin_market_value
    @stats.printPriceChanges :sell
    puts "Current bitcoin price: $#{@current_market_data[:btc_usd_sell].usd_round}"
    puts "Waiting for a gain of #{@min_percent_gain*100}%"
    puts "Percent change in bitcoin conversion value: " + "#{((btc_percent_change*100).percent_round.to_s + "%").color_by_sign}"
    puts "Sale_confidence: #{@stats.sale_confidence}"
    if btc_percent_change > @min_percent_gain
      puts "Minimum sale threshold reached"
      if @stats.sale_confidence > 15
        sell current_bitcoin_market_value, last_purchase[:btc]
      end
    end
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
        @stats.update_profit btc_usd, btc_quantity, fee
      rescue Exception => e
        puts "failure recording transaction, retrying",e
        transaction_success = false
        sleep 1
      end
    end
    refresh_fee
  end

  def stats
    @stats
  end

end