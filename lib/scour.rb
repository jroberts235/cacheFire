require 'anemone'
require 'redis'

class Scour
  def initialize(url, threads, options)
    #file  = options.config[:file]
    file = 'redis'
    redis = Redis.new

    puts "Scouring #{url} using #{threads} threads and writing to #{file}"  unless options.config[:quiet]

    progressbar = ProgressBar.create(:starting_at => 20,
                                     :total => nil)  unless options.config[:quiet]
    beginning_time = Time.now
    $log.info("Scour started at #{beginning_time}")

    Anemone.crawl(url, :threads => threads) do |anemone|
      anemone.on_every_page do |page|
        (page.links).each do |link|

          # these are hard coded for my purpose
          next if link.to_s.include?('filter') or link.to_s.include?('index') or link == nil

          redis.set((link.to_s.split('/', 4))[3], 1) 
          $log.info("Discovered: #{(link.to_s.split('/', 4))[3]}")

          progressbar.increment  unless options.config[:quiet]
        end
      end
    end
    end_time = Time.now
    timer = (end_time - beginning_time)*1000
    $log.info("Scour finished in #{timer * 60} minutes")
  end
end
