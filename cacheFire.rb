#! env jruby
$LOAD_PATH << './lib'

require 'ruby-progressbar'
require 'logger'
require 'java'
require 'scour.rb'
require 'options.rb'
require 'linkpool.rb'     
require 'job.rb'         
require 'varnish.rb'
require 'standard.rb'
require 'targeted.rb'
require 'stats.rb'

java_import 'java.util.concurrent.FutureTask'
java_import 'java.util.concurrent.LinkedBlockingQueue'
java_import 'java.util.concurrent.ThreadPoolExecutor'
java_import 'java.util.concurrent.TimeUnit'


begin
  options = Options.new
  options.parse_options
       
                 url = options.config[:url]
                port = options.config[:port]
             threads = options.config[:threads].to_i
               links = options.config[:links].to_i

  # create the thread pool
  executor = ThreadPoolExecutor.new(threads, # core_pool_treads
                                    (threads * 3),     # max_pool_threads
                                    300,       # keep_alive_time
                                    TimeUnit::SECONDS,
                                    LinkedBlockingQueue.new)
                                    


  # setup global logging
  $log = Logger.new('cacheFire.log', 'daily')
  $log.datetime_format = "%Y-%m-%d %H:%M:%S"


  # Purge all links from the cache
  if options.config[:purge]
    puts 'Purging all links from cache'
    linkPool = LinkPool.new(options) 
    linkPool.purge 
  end


  # Scour Mode
  # crawl URL and generate $file.dat
  if options.config[:scour]
    Scour.new(url, threads, options)
  end


  # Retrieve Mode
  # use the $filename.dat file to GET random links from URL 
  if options.config[:retrieve]

            h = PersistentHTTP.new(
                :name         => 'cacheFire',
                :pool_size    => 2048,
                :pool_timeout => 10,
                :warn_timeout => 0.25,
                :force_retry  => true,
                :url          => url,
                :port         => port
            )

    linkPool = LinkPool.new(options) 
    linkPool.read 

    stats = Stats.new(options, linkPool)

    if options.config[:targeted]
      ratio = options.config[:targeted].to_i
      puts "Heating cache to #{ratio}% using #{threads} thread(s)."  unless options.config[:quiet]
      run_targeted(executor, ratio, threads, h, url, linkPool, options, stats)
    else
      puts "Getting #{links} links using #{threads} thread(s)."  unless options.config[:quiet]
      run_standard(executor, links, threads, h, url, linkPool, options, stats)
    end

  end
ensure 
  executor.shutdown() if options.config[:retrieve]
  $log.close if $log
end
