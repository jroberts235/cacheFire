require 'anemone'
require 'redis'

class Scour
  def initialize(options)
        url = options.config[:url]
    threads = options.config[:threads].to_i
      depth = options.config[:depth].to_i
      redis = Redis.new
    counter = 0

    puts "You don't need to specify --redis when using Scour mode." if options.config[:redis]
    puts "Scouring #{url} using #{threads} threads and writing to Redis:" unless options.config[:quiet]


    progressbar = ProgressBar.create(:starting_at => 20,
                                     :total => nil)  unless options.config[:quiet]

    beginning_time = Time.now
    @log.info("Scour started at #{beginning_time}")

    Anemone.crawl( url,
                   :discard_page_bodies => true,
                   :threads => threads,
                   :user_agent => "cacheFire",
                   :delay => 0,
                   :obey_robots_txt => false,
                   :depth_limit => depth, 
                   :accept_cookies => false,
                   :skip_query_strings => true,
                   :read_timeout => nil ) do |anemone|
      anemone.on_every_page do |page|
        (page.links).each do |link|

          # I wanted to filter out some links
          # these are hard coded for my purpose. Feel free to remove or adjust.
          # This can also be done by anemone as is probably better that way.
          next if link.to_s.include?('filter') or link.to_s.include?('index') or link == nil

          path = ((link.to_s.split('/', 4))[3]).gsub!(/^/, '/') # extract the path from link 
          redis.set(path, 1) # set the value to arbitrary val (it's not used for anything)
          @log.info("Discovered: #{path}")

          progressbar.increment  unless options.config[:quiet]
          counter += 1
        end
      end
    end
    end_time = Time.now
    timer = (end_time - beginning_time)/60
    puts "Finished in #{timer} minutes."
    @log.info("#{counter} links Scoured in #{timer} minutes")
  end
end
