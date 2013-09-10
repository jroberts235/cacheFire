#! env jruby
$LOAD_PATH << './lib'

require 'anemone'
require 'ruby-progressbar'
require 'logger'
require 'persistent_http'
require 'mixlib/cli'
require 'java'
require 'cachewarmer.rb'
require 'counter.rb'     
require 'job.rb'         
require 'skip.rb'

begin

  # call CacheWarmer and parse options
  cw = CacheWarmer.new
  cw.parse_options

  # handle the attrs passed at runtime
                 url = cw.config[:url]
             threads = cw.config[:threads].to_i
  numberOfpagesToGet = cw.config[:pages].to_i

  # create a thread pool
  executor = ThreadPoolExecutor.new(threads, # core_pool_treads
                                    256, # max_pool_threads
                                    5,  # keep_alive_time
                                    TimeUnit::SECONDS,
                                    LinkedBlockingQueue.new)

  # setup logging
  $log = Logger.new('cacheFire.log', 'daily')
  $log.datetime_format = "%Y-%m-%d %H:%M:%S"


  # Scour
  # crawl URL and generate scour.dat file if asked to
  if cw.config[:scour]
    puts "Crawling #{url} looking for links..."

    # some eye candy while you wait
    $progressbar = ProgressBar.create(:starting_at => 20, 
                                      :total => nil)
    cw.crawlAndWriteScourFile(url) 
    puts "Done! Now you can run in Retrieve mode."
  end

  # Retrieve
  # use the scour.dat file to GET random pages from URL 
  # URI's will only be loaded once
  if cw.config[:retrieve]

    # some eye candy while you wait
    $progressbar = ProgressBar.create(:format => '%a <%B> %p%% %t',
                                   :starting_at => 0,
                                   :total => numberOfpagesToGet,
                                   :smoothing => 0.8) unless cw.config[:report] 

    raise 'File scour.dat cannot be found!' unless File.exists?('scour.dat')
    
    allLinksFromFile = cw.readScourfile
    exit if cw.config[:report]

    puts "Getting #{numberOfpagesToGet} pages using #{threads} thread(s)."

    h = PersistentHTTP.new(
        :name         => 'cacheFire',
        :pool_size    => 1024,
        :pool_timeout => 5,
        :warn_timeout => 0.25,
        :force_retry  => true,
        :url          => url
    )

    tasks = [] # array to track threads
    s = Skip.new # method to track URI's that have been called
    c = Counter.new # counter method for cache hits and misses

    (numberOfpagesToGet/threads).times do
      threads.times do |t|
        uri = "#{url}/#{allLinksFromFile.sample}"
        #next if (s.cached).include?(uri) # skip if hit previously
        task = FutureTask.new(Job.new(h,uri,c,s))
        executor.execute(task)
        tasks << task
      end

      # wait for all threads to complete
      tasks.each do |t|
        t.get
      end
    end
    $progressbar.finish
    # report counter stats
    puts "Cache-Hits: #{c.hits}"
    puts "Cache-Miss: #{c.total - c.hits}"
  end
ensure 
  executor.shutdown()
  $log.close
end
