load '../data/database.rb'

class TransactionsDatabase < Database
  def initialize
    @name = "transactions"
    @columns = [
             [:btc, "real"],
             [:btc_usd, "real"],
             [:fee, "real"],
             [:type, "text"], #purchase/sale
             [:timestamp, "DATETIME"]
           ]
    super
  end

  def insert (btc, btc_usd, fee, type)
    @db.execute("INSERT INTO #{@name} (btc, btc_usd, fee, type, timestamp)
            VALUES (?, ?, ?, ?, datetime('now', 'localtime'))", [btc, btc_usd, fee, type.to_s])
  end

  def convert_to_keys(row)
    {
      :btc => row[0],
      :btc_usd => row[1],
      :fee => row[2],
      :type => row[3],
      :timestamp => row[4],
    }
  end
end