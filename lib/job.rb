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
    req = @h.request(Net::HTTP::Get.new("#{@url}/#{uri}"))

    @linkPool.remove(uri) if @options.config[:uniq]

    if req.get_fields('Status')
      if req.get_fields('Status').include?("404 Not Found") 
        @linkPool.error(uri)
        $log.error("404: #{uri}")
        return
      end
    end

    @linkPool.total_incr

    if req.get_fields('X-Cache')
      if req.get_fields('X-Cache').include?("HIT")
        $log.info("Hit: #{uri}")
        @linkPool.hits_incr
      else
        $log.info("Miss: #{uri}")
      end
    end

  end
end
