require 'java'
require 'persistent_http'
require 'net/http'

java_import 'java.util.concurrent.Callable'

class Job
  include Callable
  def initialize(conn_handle, url, linkPool, options, stats, path)
         @h = conn_handle
       @url = url
  @linkPool = linkPool
   @options = options
     @stats = stats
      @path = path
      @vhost = options.config[:vhost]

    raise "No connection handle provided to the job!" if @h == nil
    raise "No path provided to job!"                  if @path == nil
    raise "No url provided to the job!"               if @url == nil
  end

  def call
    beginning_time = Time.now
      req = Net::HTTP::Get.new(@path)
      req['Host'] = @vhost if @options.config[:vhost]
      req['Accept-Encoding'] = 'gzip,deflate' # this is important
      req['User-Agent'] = 'cacheFire'
      res = @h.request(req)
    end_time = Time.now

    timer = (end_time - beginning_time)*1000

    # check for and log any missing paths
    if res.get_fields('Status')
      if res.get_fields('Status').include?("404 Not Found") 
        @stats.error(@path)
        $log.error("404: #{@path}")
        return
      end
    end

    # track the total request for ratio calc 
    @stats.total_incr

    # check for and log the X-Cache header and resp times
    # track hits for ratio calc
    if res.get_fields('X-Cache')
      if res.get_fields('X-Cache').include?("HIT")
        $log.info("HIT(#{timer/1000}): #{@path}")
        @stats.hit(timer/1000)
        @stats.hits_incr
      else
        $log.info("MISS(#{timer/1000}): #{@path}")
        @stats.miss(timer/1000)
      end
    else $log.info("No 'X-Cache' Header Returned")
    end
  end
end # end of class
