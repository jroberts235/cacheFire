#! env jruby
$LOAD_PATH << './lib'

require 'ruby-progressbar'
require 'logger'
require 'java'
require 'crawl.rb'
require 'options.rb'
require 'linkpool.rb'     
require 'job.rb'         
require 'varnish.rb'
require 'standard.rb'
require 'targeted.rb'

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

  # setup global logging
  $log = Logger.new('cacheFire.log', 'daily')
  $log.datetime_format = "%Y-%m-%d %H:%M:%S"
  $log.info("\n\ncacheFire\n#{`date`}\n")

  # log the cmd options
  options.config.each do |k,v|
    $log.debug("#{k} = #{v}") if v 
  end 

  # create the thread pool
  executor = ThreadPoolExecutor.new(threads, # core_pool_treads
                                    threads,     # max_pool_threads
                                    5,       # keep_alive_time
                                    TimeUnit::SECONDS,
                                    LinkedBlockingQueue.new)


  # Purge all links from the cache
  if options.config[:purge]
    puts 'Purging all links from cache'
    linkPool = LinkPool.new(options) 
    linkPool.purge 
  end


  # Scour Mode
  # crawl URL and generate scour.dat file if asked to
  if options.config[:scour]
    puts "Crawling #{url} looking for links..." unless options.config[:quiet]
    Crawl.new(url, threads, options)
    linkPool = LinkPool.new(options)
    puts "The scour.dat file contains #{linkPool.count} entries." unless options.config[:quiet]
  end


  # Retrieve Mode
  # use the scour.dat file to GET random links from URL 
  if options.config[:retrieve]

    raise 'File scour.dat cannot be found!' unless File.exists?('scour.dat')

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

    if options.config[:targeted]
      ratio = options.config[:targeted].to_i
      puts "Heating cache to #{ratio}% using #{threads} thread(s)." unless options.config[:quiet]
      run_targeted(executor, ratio, threads, h, url, linkPool, options)
    else
      puts "Getting #{links} links using #{threads} thread(s)." unless options.config[:quiet]
      run_standard(executor, links, threads, h, url, linkPool, options)
    end
    require 'json'
    $stdout = File.open('404s.json', 'w')
    puts linkPool.errors.to_json
  end
ensure 
  executor.shutdown() if options.config[:retrieve]
  $log.close if $log
end
