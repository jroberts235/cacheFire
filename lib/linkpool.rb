$LOAD_PATH << './'
require 'readfile.rb'
require 'rest-client'
require 'redis'


class LinkPool
  attr_accessor(:count, :pool)
  def initialize(log, options)
      @log = log
    @count = 0
  @options = options
      @url = options.config[:url]
     @pool = ThreadSafe::Hash.new
  end

  def fetch
    wesley = @pool.keys.sample 
    return if wesley == nil
    path = wesley.dup 
    path.gsub!(/^/, '/') unless path.start_with?('/') 
    return path
  end

  def read
    if @options.config[:redis] # get paths from redis
      redis = Redis.new
      raise "Cannot reach local Redis server!" if redis == false
      @log.info(redis.inspect)
      redis.keys.each { |k| @pool[k] = 1 }
    else # readfile and populate the links Hash
      r = ReadFile.new(@options)
      r.open
      @pool = r.lines
    end
  end

  def count
    @pool.keys.count 
  end

  def reload
    @log.info("Reloading paths from #{options.config[:filename]}")
    self.read
  end

  def remove(path)
    @log.info("Removing: #{path}")
    @pool.delete(path)
    @log.info("Paths remaining: #{self.count}")
  end

  def purge
    host = (@options.config[:url].split(/\/\//, 2))[1]
    @log.info("Banning all current links!")
    system("/usr/local/opt/varnish/bin/varnishadm -T #{host}:6082 -S /Users/jroberts/ruby/cacheFire/secret \"ban.url .\"")
    raise "Banning operation failed!" unless $? == 0
  end
end
