class FetchMarketData
  load 'marketDatabase.rb'
  @buy, @sell = nil

  def initialize
    @marketDb = MarketDatabase.new
  end

  def fetch
    ticker = Bitstamp.ticker
    @buy, @sell = ticker.ask.to_f, ticker.bid.to_f
    @marketDb.insert @buy, @sell
    {:buy => @buy, :sell => @sell}
  end

  def getPriceChange(timechange = "-1 minute")
    return if @buy == nil
    result = @marketDb.execute("select * from market where timestamp > datetime('now', 'localtime', '#{timechange}') order by timestamp asc limit 1;").first
    {:buy => @buy - result[0].to_f, :sell => @sell - result[1].to_f}
  end
end