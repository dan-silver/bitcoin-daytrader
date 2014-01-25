class FetchMarketData
  load 'marketDatabase.rb'
  def initialize
    @marketDb = MarketDatabase.new
  end

  def fetch
    ticker = Bitstamp.ticker
    @marketDb.insert ticker.ask, ticker.bid
  end
end