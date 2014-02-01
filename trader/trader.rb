class Trader
  attr_accessor :min_percent_gain, :min_percent_drop, :transactionsDb, :marketDb, :stats
  def initialize
    @fee = nil

    #@transactionsDb.insert 0.235, 795, 0.90, :purchase
    #@transactionsDb.insert 0.25, 772, 0.97, :sale
    refresh_fee
    yield self if block_given?
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
    if last_transaction[:type] == :sale
      puts "Considering a purchase".green
      report :consider_purchase
      if consider_purchase
        puts "Minimum purchase threshold reached"
        #purchase!
      end
    else
      puts "Considering a sale".green
      report :consider_sale
      if consider_sale
        puts "Minimum sale threshold reached"
        #sell!
      end
    end
  end

  def consider_purchase
    last_sale = @transactionsDb.last :sale

    usd_avail = last_sale[:btc] * last_sale[:btc_usd] - last_sale[:fee]

    @stats.printPriceChanges :buy
    btc_percent_change(:consider_purchase) < @min_percent_drop
    '''
    purchase current_bitcoin_market_value, usd_avail
    '''
  end

  def btc_percent_change (method)
    percent_change @current_market_data[method == :consider_purchase ? :btc_usd_buy : :btc_usd_sell], @transactionsDb.last[:btc_usd]
  end

  def report(type)
    case type
      when :consider_purchase
        puts "Current bitcoin buy price: $#{@current_market_data[:btc_usd_buy].usd_round}"
        puts "Waiting for a drop of #{@min_percent_drop*100}%"
        puts "Percent change in bitcoin conversion value: " + "#{((btc_percent_change(:type)*100).percent_round.to_s+"%").color_by_sign}"
      when :consider_sale
        puts "Current bitcoin sell price: $#{@current_market_data[:btc_usd_sell].usd_round}"
        puts "Waiting for a gain of #{@min_percent_gain*100}%"
        puts "Percent change in bitcoin conversion value: " + "#{((btc_percent_change(:type)*100).percent_round.to_s + "%").color_by_sign}"
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
    last_purchase = @transactionsDb.last :purchase

    #current_bitcoin_market_value = @current_market_data[:btc_usd_sell]
    @stats.printPriceChanges :sell
    #puts "Sale_confidence: #{@stats.sale_confidence}"
    btc_percent_change(:consider_sale) > @min_percent_gain
    '''
    if @stats.sale_confidence > 15
      sell current_bitcoin_market_value, last_purchase[:btc]
    end
    '''
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