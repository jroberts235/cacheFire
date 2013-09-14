require 'java'
require 'persistent_http'

java_import 'java.util.concurrent.Callable'

class Job
  include Callable
  def initialize(conn_handle, url, linkPool, progressbar, options)
    @h        = conn_handle
    @url      = url
    @linkPool = linkPool
    @options  = options
    @progressbar = progressbar
  end
  def call
    uri = @linkPool.pool.sample
    req = @h.request(Net::HTTP::Get.new("#{@url}/#{uri}"))

    @progressbar.increment
    @linkPool.total_incr

    if req.get_fields('X-Cache').include?("HIT")
      $log.info("Hit: #{uri.chomp}")
      @linkPool.hits_incr
      @linkPool.remove(uri) if @options.config[:prune]
    else
      $log.info("Miss: #{uri.chomp}")
    end
  end
end
