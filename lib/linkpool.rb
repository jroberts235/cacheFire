$LOAD_PATH << './'
require 'readfile.rb'
require 'thread_safe'

class LinkPool
  attr_accessor( :total, :hits, :ratio, :pool )
  def initialize( options )
    @total   = 0
    @hits    = 0
    @ratio   = 0
    @pool    = ThreadSafe::Array.new
    @options = options
  end
  def read
    # Call readfile and populate the links array
    r = ReadFile.new( @options )
    r.open # open the file for reading
    @pool = r.lines.uniq
  end
  def reload
    self.read
    $log.info("Reloading scour.dat")
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
  def remove(uri)
    @pool.delete(uri) 
    $log.info("removing #{uri.chomp}")
    $log.info("Pool Size: #{@pool.count}")
  end
end
