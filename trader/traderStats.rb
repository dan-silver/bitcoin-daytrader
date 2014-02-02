load '../general_library.rb'
class TraderStats
  def initialize(marketDb)
  	@marketDb = marketDb
  end

  def printPriceChanges(type)
    times = ["1 minute", "2 minutes", "5 minutes", "10 minutes", "20 minutes"]
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