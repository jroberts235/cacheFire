#!/Users/jroberts/.rvm/rubies/jruby-1.7.3/bin/jruby

require 'anemone'
require 'ruby-progressbar'
require 'logger'
require 'persistent_http'
require 'mixlib/cli'
require 'java'

# 'java_import' is used to import java classes
java_import 'java.util.concurrent.Callable'
java_import 'java.util.concurrent.FutureTask'
java_import 'java.util.concurrent.LinkedBlockingQueue'
java_import 'java.util.concurrent.ThreadPoolExecutor'
java_import 'java.util.concurrent.TimeUnit'

class CacheWarmer 
  include Mixlib::CLI

  option :url,
    :short => "-u URL",
    :long => "--url URL",
    :description => "URL to access",
    :required => true

  option :report,
    :short => "-R",
    :long => "--Report",
    :boolean => true,
    :description => "Count and report the number of links in scour.dat",
    :default => false

  option :threads,
    :short => "-t threads",
    :long => "--threads threads",
    :description => "Number of parallel threads to use",
    :default => 1

  option :scour,
    :short => "-s",
    :long => "--scour",
    :boolean => true,
    :description => "scour URL and build data file?",
    :default => false

  option :retrieve,
    :short => "-r",
    :long => "--retrieve",
    :boolean => true,
    :description => "Read the data from scour.dat and pick random URLs to hit",
    :default => false

  option :pages,
    :short => "-p pages",
    :long => "--pages pages",
    :description => "Number of pages to retrieve",
    :default => 100

  option :help,
    :long => "--help",
    :short => "-h",
    :description => "Show this message",
    :on => :tail,
    :show_options => true,
    :boolean => true,
    :exit => 0

  def crawlAndWriteScourFile(url)
    links = []
    Anemone.crawl(url) do |anemone|
      anemone.threads = 15
    puts "called #{url}"
      anemone.on_every_page do |page|
        puts page.links
        (page.links).each do |link|
          puts link
          unless links.include?(link) and link != nil
            links << link
            File.open('scour.dat', 'a') do |file| 
              file << "#{(link.to_s.split('/', 4))[3]}\n"
            end 
            $progressbar.increment
          end
        end
      end
    end
    puts links
  end
  
  def readScourfile
    lines = []
    $log.info("Reading scour.dat")
    File.open("scour.dat", "r").each_line do |line|
      lines << line 
    end
    puts "Read #{lines.count} lines from dat file"
    puts "De-duping... #{lines.uniq.count} remaining"
    $log.info("Read #{lines.count} lines from dat file")
    $log.info("De-duping... #{lines.uniq.count} remaining")
    return lines.uniq
  end
end # Class end

class Job
  include Callable
  def initialize(h,uri)
    @uri = uri
    @h   = h
  end
  def call
    @h.request
    $log.info("getting #{@uri.chomp}")
    $progressbar.increment
  end
end # Class end


begin

  # create a thread pool
  executor = ThreadPoolExecutor.new(256, # core_pool_treads
                                    512, # max_pool_threads
                                    60,  # keep_alive_time
                                    TimeUnit::SECONDS,
                                    LinkedBlockingQueue.new)

  # setup logging
  $log = Logger.new('cacheFire.log', 'daily')
  $log.datetime_format = "%Y-%m-%d %H:%M:%S"

  # call myclass and parse options
  cw = CacheWarmer.new
  cw.parse_options

  # handle the attrs passed at runtime
                 url = cw.config[:url]
             threads = cw.config[:threads].to_i
  numberOfpagesToGet = cw.config[:pages].to_i


  # crawl and generate scour.dat file if asked to
  if cw.config[:scour]
    puts "Crawling #{url} looking for links..."

    # some eye candy
    $progressbar = ProgressBar.create(:starting_at => 20, 
                                      :total => nil)
    cw.crawlAndWriteScourFile(url) 
    puts "Done!"
  end


  # use the scour.dat file to GET random pages from URL 
  if cw.config[:retrieve]

    # some eye candy
    $progressbar = ProgressBar.create(:format => '%e <%B> %p%% %t',
                                   :starting_at => 0,
                                   :total => numberOfpagesToGet,
                                   :smoothing => 0.8) unless cw.config[:report] 

    raise 'File scour.dat cannot be found!' unless File.exists?('scour.dat')
    
    allLinksFromFile = cw.readScourfile
    exit if cw.config[:report]

    puts "Getting #{numberOfpagesToGet} pages using #{threads} thread(s)."

    h = PersistentHTTP.new(
        :name         => 'cacheFire',
        :pool_size    => 512,
        :pool_timeout => 5,
        :warn_timeout => 0.25,
        :force_retry  => true,
        :url          => url
    )

    tasks = []
    (numberOfpagesToGet/threads).times do
      threads.times do |t|
        uri = "#{url}#{allLinksFromFile.sample}"
        task = FutureTask.new(Job.new(h,uri))
        executor.execute(task)
        tasks << task
      end

      # wait for all threads to complete
      tasks.each do |t|
        t.get
      end
    end
  end
ensure 
  executor.shutdown()
  $log.close
end
