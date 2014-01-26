load '../data/database.rb'

class MarketDatabase < Database
  def initialize
    @name = "market"
    @columns = [
             [:btc_usd_buy, "real"],
             [:btc_usd_sell, "real"],
             [:timestamp, "DATETIME"]
           ]
    super
  end

  def insert (buy, sell)
    @db.execute("INSERT INTO #{@name} (btc_usd_buy, btc_usd_sell, timestamp)
            VALUES (?, ?, datetime('now', 'localtime'))", [buy, sell])
  end


  def convert_to_keys(row)
    {
      :btc_usd_buy => row[0],
      :btc_usd_sell => row[1],
      :timestamp => row[2]
    }
  end
end