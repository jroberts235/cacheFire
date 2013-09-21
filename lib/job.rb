require 'java'
require 'persistent_http'
require 'net/http'

java_import 'java.util.concurrent.Callable'

class Job
  include Callable
  def initialize(conn_handle, url, linkPool, options, stats)
    @h        = conn_handle
    @url      = url
    @linkPool = linkPool
    @options  = options
    @stats    = stats
  end
  def call
    # pull a rnd link from the hash
    path = @linkPool.pool.keys.sample.dup
    path.gsub!(/^/, '/')  unless path.start_with?('/')

    beginning_time = Time.now
      req = Net::HTTP::Get.new(path)
      req['Accept-Encoding'] = 'gzip,deflate' # this is important
      req['User-Agent'] = 'cacheFire'
      res = @h.request(req)
    end_time = Time.now

    timer = (end_time - beginning_time)*1000

    @linkPool.remove(path)  if (@options.config[:uniq] or @options.config[:target])

    # check for and log any missing paths
    if res.get_fields('Status')
      if res.get_fields('Status').include?("404 Not Found") 
        @stats.error(path)
        $log.error("404: #{path}")
        return
      end
    end

    # track the total request for ratio calc 
    @stats.total_incr

    # check for and log the X-Cache header and resp times
    # track hits for ratio calc
    if res.get_fields('X-Cache')
      if res.get_fields('X-Cache').include?("HIT")
        $log.info("HIT(#{timer/1000}): #{path}")
        @stats.hit(timer/1000)
        @stats.hits_incr
      else
        $log.info("MISS(#{timer/1000}): #{path}")
        @stats.miss(timer/1000)
      end
    end
  end
end # end of class
