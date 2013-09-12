#! env jruby
$LOAD_PATH << './lib'

require 'ruby-progressbar'
require 'logger'
require 'java'
require 'crawl.rb'
require 'options.rb'
require 'linkpool.rb'     
require 'job.rb'         

java_import 'java.util.concurrent.FutureTask'
java_import 'java.util.concurrent.LinkedBlockingQueue'
java_import 'java.util.concurrent.ThreadPoolExecutor'
java_import 'java.util.concurrent.TimeUnit'

begin

  # options
  options = Options.new
  options.parse_options

                 url = options.config[:url]
             threads = options.config[:threads].to_i
          pagesToGet = options.config[:pages].to_i unless options.config[:target]
              target = 75 if options.config[:target]

  # options end

  # create a thread pool
  executor = ThreadPoolExecutor.new(threads, # core_pool_treads
                                    256, # max_pool_threads
                                    5,  # keep_alive_time
                                    TimeUnit::SECONDS,
                                    LinkedBlockingQueue.new)
  # thread pool end

  # setup logging
  $log = Logger.new('cacheFire.log', 'daily')
  $log.datetime_format = "%Y-%m-%d %H:%M:%S"
  # logging end


  # Scour Mode
  # crawl URL and generate scour.dat file if asked to
  if options.config[:scour]
    puts "Crawling #{url} looking for links..."
    
    Crawl.new(url, threads)

    puts "Done! Now you can run in Retrieve mode."
  end
  # scour mode end


  # Retrieve Mode
  if options.config[:retrieve] # Targeted Retreive 
    raise 'File scour.dat missing. Run in scour mode to create it.' unless File.exists?('scour.dat')

    # setup peristent connection to url
    h = PersistentHTTP.new(
        :name         => 'cacheFire',
        :pool_size    => 1024,
        :pool_timeout => 5,
        :warn_timeout => 0.25,
        :force_retry  => true,
        :url          => url
    )

    linkPool = LinkPool.new # class for pool mngmt / cache hits and misses
    linkPool.read

    tasks = [] # array to track threads

    # loop through the pool, either using target or # of pages.
    if options.config[:target]

    progressbar = ProgressBar.create(:starting_at => 20,
                                      :total => nil) if options.config[:target]

      linkPool.stats # update the ratio
      puts "Pulling random pages until the cache ratio is #{target}"
      while linkPool.ratio <= target  do 
        task = FutureTask.new(Job.new(h, url, linkPool, progressbar, options))
        executor.execute(task)
        tasks << task
        linkPool.stats # update the ratio
      end

      tasks.each do |t|
        t.get
      end
    
    else # Basic Retrieve
      progressbar = ProgressBar.create(:format => '%a <%B> %p%% %t',
                                       :starting_at => 0,
                                       :total => pagesToGet,
                                       :smoothing => 0.8) unless options.config[:target]

      puts "Getting #{pagesToGet} pages using #{threads} thread(s)."
      (pagesToGet/threads).times do
        threads.times do
          task = FutureTask.new(Job.new(h, url, linkPool, progressbar, options))
          executor.execute(task)
          tasks << task
        end

        tasks.each do |t|
          t.get
        end
      end
    end
    # end of looping

    progressbar.finish
    linkPool.stats

    puts "Cache-Hits:     #{linkPool.hits}"
    puts "Cache-Miss:     #{linkPool.total - linkPool.hits}"
    puts "Hit/Miss Ratio: #{linkPool.ratio}%"
  end
  # retrieve mode end
ensure 
  executor.shutdown() if options.config[:retrieve]
  $log.close if $log
end
