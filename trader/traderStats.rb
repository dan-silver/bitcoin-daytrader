require 'colorize'
load '../rounding.rb'

class TraderStats

  def initialize(transactionsDB, marketDb)
  	@profit_this_run = 0
  	@transactionsDB = transactionsDB
  	@marketDb = marketDb
  end

  def printPriceChanges(type)
    times = ["1 minute", "2 minutes", "5 minutes", "20 minutes"]
    puts "Change over the last:"
    times.each do |time|
      puts "\t#{time}: #{getPriceChange(time)[type].usd_round.to_s.dollar_sign.color_by_sign}"
    end
  end

  def getPriceChange(timechange)
    return if @marketDb.last_row == nil
    res = @marketDb.convert_to_keys @marketDb.execute("select * from market where timestamp > datetime('now', 'localtime', '-#{timechange}') order by timestamp asc limit 1;").first
    {:buy => @marketDb.last_row[:btc_usd_buy] - res[:btc_usd_buy], :sell => @marketDb.last_row[:btc_usd_sell] - res[:btc_usd_sell]}
  end

  def sale_confidence
    confidence = 0

    times = ["1 minute", "2 minutes", "5 minutes", "20 minutes"]
    times_hash = Hash[times.map.with_index.to_a]
    price_changes = []
    times.each do |time|
      price_changes << getPriceChange(time)[:sell]
    end
    '''
    min = price_changes.min
    max = price_changes.max

    scaled_price_changes = price_changes.map {|a| scale(min,max,-100,100,a)}

    puts scaled_price_changes
    confidence += scaled_price_changes[times_hash["1 minute"]] * -10
    confidence += scaled_price_changes[times_hash["2 minutes"]] * -10
    confidence += scaled_price_changes[times_hash["5 minutes"]] * 5
    confidence += scaled_price_changes[times_hash["20 minutes"]] * 5
    '''

    #puts price_changes
    confidence += price_changes[times_hash['1 minute']] * -10
    confidence += price_changes[times_hash['2 minutes']] * -10
    confidence += price_changes[times_hash['5 minutes']] * 5
    confidence += price_changes[times_hash['20 minutes']] * 5
    confidence
  end

  def update_profit(btc_usd_current, btc_quantity, fee)
    previous_purchase = @transactionsDb.last :purchase
    #we just cashed out $ - we purchased last with $
    money_made = btc_usd_current * btc_quantity - previous_purchase[:btc_usd] * previous_purchase[:btc]
    money_made -= previous_purchase[:fee] - fee
    @profit_this_run += money_made
  end

  def profit
    @profit_this_run
  end

end