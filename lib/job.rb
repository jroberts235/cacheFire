require 'java'

# 'java_import' is used to import java classes
java_import 'java.util.concurrent.Callable'
java_import 'java.util.concurrent.FutureTask'
java_import 'java.util.concurrent.LinkedBlockingQueue'
java_import 'java.util.concurrent.ThreadPoolExecutor'
java_import 'java.util.concurrent.TimeUnit'

class Job
  include Callable
  def initialize(h,uri,c,s)
    @h   = h
    @uri = uri
    @counter = c
    @skip = s
  end
  def call
    r = @h.request(Net::HTTP::Get.new(@uri))

    $log.info("getting #{@uri.chomp}")
    $progressbar.increment

    if r.get_fields('X-Cache').include?("HIT")
      $log.info("Cache hit!")
      @skip.add(@uri) # add to skip array
      @counter.total_incr
      @counter.hits_incr
    else
      @skip.add(@uri) # add to skip array
      @counter.total_incr
    end
  end
end # Class end
