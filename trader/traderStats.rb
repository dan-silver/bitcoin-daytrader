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
    res = @marketDb.convert_to_keys @marketDb.execute("select * from market where timestamp > datetime('now', 'localtime', '-#{timechange}') order by timestamp asc limit 1").first
    {:buy => @marketDb.last_row[:btc_usd_buy] - res[:btc_usd_buy], :sell => @marketDb.last_row[:btc_usd_sell] - res[:btc_usd_sell]}
  end

  #I am wanting to think about this class as
  #the librarian/library system
  #this may seem silly since we have databases
  #however, this is intended to reduce calls to the database
  #make the data easier to get to
  #and create whole sets of derived data, which are also easy to get to
  #this 'data' is all stored in the MarketDataPoint
  #it may be reasonable to create a MarketDataLandmark class
  #or something that is not 100% coupled to time, simply for
  #reference
  class MarketDataAggregator

    def initialize
      @array_of_data_points = []
      @most_recent_time_to_acknowledge = '2 minutes'
      @most_distant_time_to_acknowledge = '14 days'
    end

    def assemble_data_point_from_row(sqlite_market_data_row)

    end
  end

  #and this class as the books in the library
  class MarketDataPoint
    
    attr_reader :sell_value_diff_in_usd
    attr_reader :buy_value_diff_in_usd
    attr_reader :time

    attr_accessor :weight
    
    def initialize(market_data_aggregator)
      
      @sell_value_diff_in_usd = sqlite_market_data_row
      @buy_value_diff_in_usd  = nil
      @time                   = nil
      
      @weight = nil


    end
  end

  def sale_confidence
    #ben's notes:
    #get the data back to a certain point in time, and disregard the last X time of data
    #compare each point to the Current time
    #multiply the difference by the weight of the point to get the confidence adjustment
    #maintain an easily traversible structure to pull whatever we want to see out
    #example {:time=> {:usd_value_diff=>#, :weight=>#, :time=>#}}
    #create mini object to make this easier


    confidence = 0

    times = ["1 minute", "2 minutes", "5 minutes", "20 minutes"]
    times_hash = Hash[times.map.with_index.to_a]
    price_changes = []
    
    times.each do |time|
      price_changes << getPriceChange(time)[:sell]
    end

    #puts price_changes
    #only applies after minimal threshhold met
    #confidence is low when it has been met, but rates are increasing nicely
    #it gets really high when they start to head back towards the threshhold "from the top"
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