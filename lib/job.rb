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

    @linkPool.total_incr
    @linkPool.remove(uri) if @options.config[:prune]

    if req.get_fields('X-Cache').include?("HIT")
      $log.info("Hit: #{uri}")
      @linkPool.hits_incr
    else
      $log.info("Miss: #{uri}")
    end
  end
end
