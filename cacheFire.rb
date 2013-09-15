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

java_import 'java.util.concurrent.FutureTask'
java_import 'java.util.concurrent.LinkedBlockingQueue'
java_import 'java.util.concurrent.ThreadPoolExecutor'
java_import 'java.util.concurrent.TimeUnit'


def run_standard(executor, links, threads, h, url, linkPool, options)
  progressbar = ProgressBar.create(:format => '%a <%B> %p%% %t',
                                   :starting_at => 0,
                                   :total => links,
                                   :smoothing => 0.8) unless options.config[:quiet]

  tasks = [] # array to track threads

  (links/threads).times do
    if linkPool.pool.count >= 1
      threads.times do
        task = FutureTask.new(Job.new(h, url, linkPool, options))
        executor.execute(task)
        tasks << task
        progressbar.increment unless options.config[:quiet]
      end
    end

    # wait for all threads to complete
    tasks.each do |t|
      t.get
    end
   end

   # finish with some stats
   unless options.config[:quiet]
     linkPool.calc_ratio
     puts "\n"
     puts "Cache-Hits:     #{linkPool.hits}"
     puts "Cache-Miss:     #{linkPool.total - linkPool.hits}"
     puts "Hit/Miss Ratio: #{linkPool.ratio}%"
   end
end

def run_targeted(executor, ratio, threads, h, url, linkPool, options)
  raise "Targeted mode requires that varnish be installed locally" unless File.exist?('/usr/bin/varnishstat')

  progressbar = ProgressBar.create(:format => '%a %w',
                                   :starting_at => 0,
                                   :total => 100,
                                   :smoothing => 0.8) unless options.config[:quiet]

  tasks = [] # array to track threads

  until varnishRatio >= ratio do
    threads.times do
      task = FutureTask.new(Job.new(h, url, linkPool, options))
      executor.execute(task)
      tasks << task
    end
    progressbar.progress= varnishRatio unless options.config[:quiet]

    if linkPool.pool.count < threads
      linkPool.reload
    end

    # wait for all threads to complete
    tasks.each do |t|
      t.get
    end
  end
end

begin
  options = Options.new
  options.parse_options
       
                 url = options.config[:url]
                port = options.config[:port]
             threads = options.config[:threads].to_i
               links = options.config[:links].to_i

  # create the thread pool
  executor = ThreadPoolExecutor.new(threads, # core_pool_treads
                                    256,     # max_pool_threads
                                    5,       # keep_alive_time
                                    TimeUnit::SECONDS,
                                    LinkedBlockingQueue.new)

  # setup global logging
  $log = Logger.new('cacheFire.log', 'daily')
  $log.datetime_format = "%Y-%m-%d %H:%M:%S"


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
                :pool_size    => 1024,
                :pool_timeout => 2,
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

  end
ensure 
  executor.shutdown() if options.config[:retrieve]
  $log.close if $log
end
