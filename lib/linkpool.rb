$LOAD_PATH << './'
require 'readfile.rb'
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
  attr_accessor( :count, :pool )

  def initialize(options)
    @count   = 0
    @options = options
    @url     = options.config[:url]
    @pool    = ThreadSafe::Hash.new
  end

  def read
    # Call readfile and populate the links Hash
    r = ReadFile.new( @options )
    r.open 
    @pool = r.lines
  end

  def reload
    self.read
    $log.info("Reloading paths from #{options.config[:filename]}")
  end

  def remove(path)
    $log.info("Removing #{path} from pool")
    @pool.delete(path) 
    $log.info("Paths remaining: #{@pool.keys.count}")
  end

  def purge 
    self.read
    @pool.keys.each do |path|
      $log.info("Purging #{@url + path}")
      RestClient.purge "#{@url}:6081#{path}"
    end
  end
end
