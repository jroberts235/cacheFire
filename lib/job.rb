require 'java'
require 'persistent_http'

java_import 'java.util.concurrent.Callable'

class Job
  include Callable
  def initialize(http_connection, url, linkPool, progressbar)
    @h        = http_connection
    @url      = url
    @linkPool = linkPool
    @progressbar = progressbar
  end
  def call
    uri = @linkPool.pool.sample
    r = @h.request(Net::HTTP::Get.new("#{@url}/#{uri}"))

    $log.info("getting #{uri.chomp}")
    @progressbar.increment

    if r.get_fields('X-Cache').include?("HIT")
      $log.info("Cache hit!")
      @linkPool.total_incr
      @linkPool.hits_incr
    else
      @linkPool.total_incr
    end
  end
end
