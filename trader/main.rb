require 'colorize'
load 'trader.rb'

trader = Trader.new :percent_gain_for_sale => 0.012, :percent_change_for_purchase => -0.01
seconds_between_trader_runs = 5
#formatting
format_stars ="",("*"*50).cyan,""


while true do
  puts format_stars
  trader.trade
  puts "Profit this run: $#{trader.stats.profit.to_f.usd_round}"
  sleep seconds_between_trader_runs
end