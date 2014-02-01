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

  def sale_confidence
    #ben's notes:
    #get the data back to a certain point in time, and disregard the last X time of data
    #compare each point to the Current time
    #multiply the difference by the weight of the point to get the confidence adjustment
    #maintain an easily traversible structure to pull whatever we want to see out
    #example {:time=> {:usd_value_diff=>#, :weight=>#, :time=>#}}
    #create mini object to make this easier


    confidence = 0

    times = ["1 minute", "2 minutes", "5 minutes", "20 minutes"]
    times_hash = Hash[times.map.with_index.to_a]
    price_changes = []
    
    times.each do |time|
      price_changes << getPriceChange(time)[:sell]
    end

    #puts price_changes
    #only applies after minimal threshhold met
    #confidence is low when it has been met, but rates are increasing nicely
    #it gets really high when they start to head back towards the threshhold "from the top"
    confidence += price_changes[times_hash['1 minute']] * -10
    confidence += price_changes[times_hash['2 minutes']] * -10
    confidence += price_changes[times_hash['5 minutes']] * 5
    confidence += price_changes[times_hash['20 minutes']] * 5
    confidence
  end
end

class MarketDataPoint
  attr_accessor :buy_value_in_usd, :sell_value_in_usd, :time, :weight, :confidence

  def initialize
    yield self if block_given?
  end

  def btc_buy_value_change_usd(now_point)
    now_point.buy_value_in_usd - @buy_value_in_usd
  end

  def btc_sell_value_change_usd(now_point)
    now_point.sell_value_in_usd - @sell_value_in_usd    
  end

  def time_ago(now_point)
    now_point.time.to_i - @time.to_i
  end

  def before? (time)
     @time < time
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
class MarketDataAggregator
  attr_accessor :array_of_data_points

  def initialize
    @array_of_data_points = []

    #earliest and latest points, all in between will be gathered
    @most_recent_time_to_acknowledge = 30
    @most_distant_time_to_acknowledge = 3600
    
    #confidence can't be negative, but I think that makes this more intuitive
    @weight_spread = 200

    # if the max and min are Mx and Mn,
    # 
    # A is most recent
    # B is most distant
    #
    # the graph should be viewed as an Increase in weight backwards in time
    # starting at A going to B, and dipping at lowest to Mn, while peaking at Mx
    @weight_distribution = 'linear'

    @old_weights = false
  end

  def get_confidence_points_since(time_ago)
    get_points_between_seconds_ago(1,time_ago).inject([]) { |ary, e| 
      ary << {buy_conf: e.weight*e.btc_buy_value_change_usd, sell_conf: e.weight*e.btc_sell_value_change_usd} 
    }
  end

  #add the logic for linear vs log etc. here
  def get_time_weight(time_ago)
    return time_ago/@weight_spread if @weight_distribution == 'linear'
    return Math.log(time_ago)/@weight_spread if (@weight_distribution == 'log')
  end

  def assign_weights
    @old_weights = false
    now = Time.new
    @array_of_data_points.map do |e| 
      e.weight = 0
      unless !e.before? (now-@most_recent_time_to_acknowledge) || (e.before? now-@most_distant_time_to_acknowledge)
        e.weight = get_time_weight(now.to_i - e.time.to_i + @most_recent_time_to_acknowledge)
      end
    end
  end


  #a running set of points showing the differences between points over time
  def get_deltas_since(seconds_ago)
    data_points_since_then = get_points_between_seconds_ago(1,seconds_ago)#not include now
    delta_points = data_points_since_then.inject([]) { |num_list, elem| num_list << 
      {
        buy_delta: (elem.buy_value_in_usd - (num_list.last.nil? ? 0 : num_list.last[:buy].to_f)), 
        sell_delta: (elem.sell_value_in_usd - (num_list.last.nil? ? 0 : num_list.last[:sell].to_f)),
        buy: elem.buy_value_in_usd,
        sell: elem.sell_value_in_usd,
        time: elem.time
      }
    }
    delta_points.shift
    delta_points
  end

  #type = :buy_delta or :sell_delta
  def match_deltas_with_weights(seconds_ago, type)
    deltas = get_deltas_since seconds_ago
    total_weighted_delta = 0
    weight_increment = (@max_weight - @min_weight) / deltas.length
    current_weight = @min_weight
    deltas.each do |delta|
      current_weight += weight_increment 
      total_weighted_delta += delta[type] * current_weight
    end
    total_weighted_delta
  end

  #get the fluctuation between points as hash of buy: sell:
  def get_jitter_since_seconds_ago(seconds_ago)
    data_points_since_then = get_points_between_seconds_ago(1,seconds_ago)#not include now
    jitter_points = data_points_since_then.inject([]) { |num_list, elem| num_list << 
      {# i know this will bug the hell out of you (dan) but i didn't want to refactor this and the deltas code
        buy_jitter: (elem.buy_value_in_usd - (num_list.last.nil? ? 0 : num_list.last[:buy].to_f)).abs, 
        sell_jitter: (elem.sell_value_in_usd - (num_list.last.nil? ? 0 : num_list.last[:sell].to_f)).abs,
        buy: elem.buy_value_in_usd,
        sell: elem.sell_value_in_usd,
        time: elem.time
      }
    }
    jitter_points.shift
    jitter_points
  end

  #you specify seconds ago min & seconds ago max to find a set of points
  def get_points_between_seconds_ago(recent_time, distant_time) 
    now = Time.new
    assign_weights if @old_weights  
    timeset = @array_of_data_points.select { |e| e.time < now - recent_time && e.time > now - distant_time }
    timeset.reverse
  end

  #youngest point
  def most_recent_data_point
    most_recent = @array_of_data_points.first
    return most_recent if !most_recent.nil?
  end

  #oldest point
  def most_distant_data_point
    most_distant = @array_of_data_points.last
    return most_distant if !most_distant.nil?
  end

  #this function adds the point to the array where it belongs if it can
  def place_data_point(data_point)
    @old_weights = true #the weights need to be re-updated
    #it is invalid to place points in between, they may only be at end or beginning
    return @array_of_data_points.unshift data_point if most_recent_data_point.nil?
    return @array_of_data_points.unshift data_point if data_point.before? most_recent_data_point.time  
    return @array_of_data_points.push data_point    if !data_point.before?  most_distant_data_point.time 
    false
  end

  #this function ONLY assembles, it does not make assumptions
  #about the organization of the data
  def assemble_data_point_from_row(market_data_row)
    MarketDataPoint.new do |m|
      m.buy_value_in_usd  = market_data_row[:btc_usd_buy]
      m.sell_value_in_usd = market_data_row[:btc_usd_sell]
      m.time = market_data_row[:timestamp]
    end
  end
end