$LOAD_PATH << './'
require 'readfile.rb'

class LinkPool
  attr_accessor( :total, :hits, :pool )
  def initialize
    @total  = 0
    @hits   = 0
    @pool   = [] 
  end
  def read
    # Call readfile and populate the links array
    r = ReadFile.new 
    r.open # open the file for reading
    @pool = r.lines
  end
  def reload
    self.read
  end
  def total_incr
    @total += 1
  end
  def hits_incr
    @hits  += 1
  end
  def remove(uri)
    @pool.delete(uri) 
    $log.info("removing #{uri.chomp}")
    $log.info("Pool Size: #{@pool.count}")
  end
end
