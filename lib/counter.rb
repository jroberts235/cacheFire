class Counter
  attr_accessor( :total, :hits )
  def initialize
    @total = 0
    @hits  = 0
  end
  def total_incr
    @total += 1
  end
  def hits_incr
    @hits  += 1
  end
end
