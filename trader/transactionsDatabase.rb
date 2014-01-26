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

  def execute(cmd)
    @db.execute cmd
  end
end