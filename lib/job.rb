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
    raise 'Pool exhausted!' if @linkPool.pool.count == 0
    uri = @linkPool.pool.sample
    req = @h.request(Net::HTTP::Get.new("#{@url}/#{uri}"))

    @progressbar.increment
    @linkPool.total_incr
    @linkPool.remove(uri) if @options.config[:purge]

    $log.info("getting #{uri.chomp}")

    if req.get_fields('X-Cache').include?("HIT")
      $log.info("Cache hit")
      @linkPool.hits_incr
    end
  end
end
