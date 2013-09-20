require 'thread_safe'

class Stats
  attr_accessor( :total, :hits, :ratio, :errors)
  def initialize(options, linkPool)
    @total      = 0
    @hits       = 0
    @ratio      = 0
    @options    = options
    @errors     = ThreadSafe::Array.new
    @miss_rates = ThreadSafe::Array.new
    @hit_rates  = ThreadSafe::Array.new
  end
  def total_incr
    @total += 1
  end
  def hits_incr
    @hits  += 1
  end
  def calc_ratio
    @ratio = ((self.hits.to_f / self.total.to_f) * 100).to_i if @total > 0
  end
  def error(path)
    @errors << path
  end
  def miss(time)
    @miss_rates << time
  end
  def hit(time)
    @hit_rates << time
  end
  def miss_avg
    @miss_rates.inject{ |sum, el| sum + el }.to_f / @miss_rates.size
  end
  def hit_avg
    @hit_rates.inject{ |sum, el| sum + el }.to_f / @hit_rates.size
  end
end # end of class
