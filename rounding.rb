class Float
  def btc_round
    self.round 6
  end
  def usd_round
    self.round 2
  end
  def percent_round
    self.round 4
  end
end