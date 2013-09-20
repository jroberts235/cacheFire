$LOAD_PATH << './'
require 'readfile.rb'
require 'thread_safe'
require 'rest-client'

class Net::HTTP::Purge < Net::HTTPRequest
  METHOD = 'PURGE'
  REQUEST_HAS_BODY = false
  RESPONSE_HAS_BODY = true
end

module RestClient
  def self.purge(url, headers={}, &block)
    Request.execute(:method => :purge, :url => url, :headers => headers, &block)
  end
end


class LinkPool
  attr_accessor( :count, :total, :hits, :ratio, :pool, :errors)
  def initialize(options)
    @total   = 0
    @hits    = 0
    @ratio   = 0
    @count   = 0
    @options = options
    @url     = options.config[:url]
    @errors  = ThreadSafe::Array.new
    @pool    = ThreadSafe::Hash.new
    @miss_rates = ThreadSafe::Array.new
    @hit_rates  = ThreadSafe::Array.new
  end
  def read
    # Call readfile and populate the links Hash
    r = ReadFile.new( @options )
    r.open # open the file for reading
    @pool = r.lines
  end
  def count
    self.read
    @count = @pool.keys.count
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
    $log.info("Pruning #{uri} from link pool")
    @pool.delete(uri) 
    $log.info("Links remaining: #{@pool.keys.count}")
  end
  def error(uri)
    @errors << uri
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
  def purge 
    self.read
    @pool.keys.each do |uri|
      $log.info("Purging #{@url + uri}")
      RestClient.purge "#{@url}:6081#{uri}"
    end
  end
end
