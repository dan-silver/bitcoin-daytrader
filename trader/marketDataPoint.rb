class MarketDataPoint
  attr_accessor :buy_value_in_usd, :sell_value_in_usd, :time, :weight, :confidence

  def initialize
    yield self
  end

  def btc_buy_value_change_usd(now_point)
    now_point.buy_value_in_usd - @buy_value_in_usd
  end

  def btc_buy_value_change_perc(now_point)#relative to now, since otherwise it'd be crazy to think about
    btc_buy_value_change_usd(now_point) / now_point.buy_value_in_usd
  end

  def btc_sell_value_change_usd(now_point)
    now_point.sell_value_in_usd - @sell_value_in_usd
  end

  def btc_sell_value_change_perc(now_point)
    btc_sell_value_change_usd(now_point) / now_point.sell_value_in_usd
  end

  def time_ago(now_point)
    now_point.time.to_i - @time.to_i
  end

  def before? (time)
     @time < time
  end
end