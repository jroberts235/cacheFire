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
  options = Options.new
  options.parse_options

                 url = options.config[:url]
             threads = options.config[:threads].to_i
  numberOfpagesToGet = options.config[:pages].to_i

  # create a thread pool
  executor = ThreadPoolExecutor.new(threads, # core_pool_treads
                                    256, # max_pool_threads
                                    5,  # keep_alive_time
                                    TimeUnit::SECONDS,
                                    LinkedBlockingQueue.new)

  # setup logging
  $log = Logger.new('cacheFire.log', 'daily')
  $log.datetime_format = "%Y-%m-%d %H:%M:%S"


  # Scour Mode
  # crawl URL and generate scour.dat file if asked to
  if options.config[:scour]
    puts "Crawling #{url} looking for links..."
    
    Crawl.new(url, threads)

    puts "Done! Now you can run in Retrieve mode."
  end


  # Retrieve Mode
  # use the scour.dat file to GET random pages from URL 
  # URI's will only be loaded once
  if options.config[:retrieve]

    raise 'File scour.dat cannot be found!' unless File.exists?('scour.dat')

    progressbar = ProgressBar.create(:format => '%a <%B> %p%% %t',
                                   :starting_at => 0,
                                   :total => numberOfpagesToGet,
                                   :smoothing => 0.8) unless options.config[:report] 

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
    puts "Getting #{numberOfpagesToGet} pages using #{threads} thread(s)."

    (numberOfpagesToGet/threads).times do 
      threads.times do 
        task = FutureTask.new(Job.new(h, url, linkPool, progressbar))
        executor.execute(task)
        tasks << task
      end

      # wait for all threads to complete
      tasks.each do |t|
        t.get
      end
    end

    progressbar.finish
    puts "Cache-Hits:     #{linkPool.hits}"
    puts "Cache-Miss:     #{linkPool.total - linkPool.hits}"
    puts "Hit/Miss Ratio: #{((linkPool.hits.to_f / linkPool.total.to_f) * 100).to_i}%"
  end
ensure 
  executor.shutdown() if options.config[:retrieve]
  $log.close if $log
end
