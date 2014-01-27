class MarketData
  load 'marketDatabase.rb'

  def initialize
    @marketDb = MarketDatabase.new
    @buy, @sell = nil
    @btc_price = 850.0
    @speed_samples = []
    @buy_speed_average = nil
    @sell_speed_average = nil
    populate_speed_array
  end

  def fetch
    

    ticker = Bitstamp.ticker
    # @rndm = Random.new
    # change = @rndm.rand(-30.0...30.0)
    # puts change
    #@btc_price += change

    @buy, @sell = ticker.ask.to_f, ticker.bid.to_f
    adjust_speed
    # @buy, @sell = @btc_price, @btc_price
    database_insert_success = false
    while !database_insert_success
      begin
        @marketDb.insert @buy, @sell
        database_insert_success =true
      rescue Exception => e
        puts "Database insert error",e
        database_insert_success = false
      end
    end
    {:buy => @buy, :sell => @sell}
  end

  def getPriceChange(timechange = "1 minute")
    return if @buy == nil
    result = @marketDb.execute("select * from market where timestamp > datetime('now', 'localtime', '-#{timechange}') order by timestamp asc limit 1;").first
    {:buy => @buy - result[0].to_f, :sell => @sell - result[1].to_f}
  end

  def adjust_speed
    @speed_samples.pop
    last_record = (@marketDb.last_rows 1).first
    @speed_samples.unshift ({:buy => @buy-last_record[:btc_usd_buy], :sell => @sell-last_record[:btc_usd_sell]})
    buy_sum = @speed_samples.reduce (0) { |sum,e| sum + e[:buy] }
    sell_sum = @speed_samples.reduce (0) { |sum,e| sum + e[:sell] }
    @buy_speed_average = buy_sum/@speed_samples.length
    @sell_speed_average = sell_sum/@speed_samples.length
    puts "buy_speed_average: #{@buy_speed_average}"
    puts "sell_speed_average: #{@sell_speed_average}"
  end

  def populate_speed_array
    last_15 = @marketDb.last_rows 60
    (0..58).each do |i|
      row = last_15[i]
      next_row = last_15[i+1] 
      sell = row[:btc_usd_sell]-next_row[:btc_usd_sell]
      buy = row[:btc_usd_buy]-next_row[:btc_usd_buy]
      @speed_samples << {:buy => buy, :sell => sell}
    end
  end

end
