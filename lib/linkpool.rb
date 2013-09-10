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
  def total_incr
    @total += 1
  end
  def hits_incr
    @hits  += 1
  end
  def remove(uri_to_remove_from_pool)
    @pool.delete(uri_to_remove_from_pool) 
  end
end
