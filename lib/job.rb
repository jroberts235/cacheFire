require 'java'
require 'persistent_http'

java_import 'java.util.concurrent.Callable'

class Job
  include Callable
  def initialize(conn_handle, url, linkPool, options)
    @h        = conn_handle
    @url      = url
    @linkPool = linkPool
    @options  = options
  end
  def call

  uri = @linkPool.pool.keys.sample

    beginning_time = Time.now
      req = Net::HTTP::Get.new("#{uri}")
      req['Accept-Encoding'] = 'gzip,deflate'
      req['User-Agent'] = 'cacheFire'
      res = @h.request(req)
    end_time = Time.now

    timer = (end_time - beginning_time)*1000

    @linkPool.remove(uri) if @options.config[:uniq]

    if res.get_fields('Status')
      if res.get_fields('Status').include?("404 Not Found") 
        @linkPool.error(uri)
        $log.error("404: #{uri}")
        return
      end
    end

    @linkPool.total_incr

    if res.get_fields('X-Cache')
      if res.get_fields('X-Cache').include?("HIT")
        $log.info("HIT(#{timer/1000}): #{uri}")
        @linkPool.hit(timer/1000)
        @linkPool.hits_incr
      else
        $log.info("MISS(#{timer/1000}): #{uri}")
        @linkPool.miss(timer/1000)
      end
    end

  end
end
