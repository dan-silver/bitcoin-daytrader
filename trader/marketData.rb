class MarketData
  load 'marketDatabase.rb'

  def initialize
    @marketDb = MarketDatabase.new
    @buy, @sell = nil
    @btc_price = 850.0  
  end

  def fetch
    #ticker = Bitstamp.ticker
    # @rndm = Random.new
    # change = @rndm.rand(-30.0...30.0)
    # puts change
    #@btc_price += change
    @buy, @sell = ticker.ask.to_f, ticker.bid.to_f
    # @buy, @sell = @btc_price, @btc_price
    @marketDb.insert @buy, @sell
    {:buy => @buy, :sell => @sell}
  end

  def getPriceChange(timechange = "-1 minute")
    return if @buy == nil
    result = @marketDb.execute("select * from market where timestamp > datetime('now', 'localtime', '#{timechange}') order by timestamp asc limit 1;").first
    {:buy => @buy - result[0].to_f, :sell => @sell - result[1].to_f}
  end
end