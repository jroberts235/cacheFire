$LOAD_PATH << './'
require 'readfile.rb'

class LinkPool
  attr_accessor( :total, :hits, :ratio, :pool )
  def initialize
    @total = 0
    @hits  = 0
    @ratio = 0
    @pool  = [] 
  end
  def read
    # Call readfile and populate the links array
    r = ReadFile.new 
    r.open # open the file for reading
    @pool = r.lines
  end
  def total_incr
    @total += 1
  end
  def hits_incr
    @hits  += 1
  end
  def stats
    @ratio = ((self.hits.to_f / self.total.to_f) * 100).to_i
  end
  def remove(uri)
    @pool.delete(uri) 
    $log.info("#{uri.chomp} - Purged from pool. Pool size: #{@pool.count}")
  end
end
