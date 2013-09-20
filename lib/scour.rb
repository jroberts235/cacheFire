require 'anemone'

class Scour
  def initialize(url, threads, options)
    links    = []
    filename = options.config[:filename]

    dataFile = File.new filename, "w"
    dataFile.close

    progressbar = ProgressBar.create(:starting_at => 20,
                                     :total => nil) unless options.config[:quiet]
    beginning_time = Time.now
    $log.info("Crawl started at #{beginning_time}")
    Anemone.crawl(url) do |anemone|
      anemone.threads = threads
      anemone.on_every_page do |page|
        (page.links).each do |link|
          unless links.include?(link) and link != nil
            links << link
            File.open(filename, 'a') do |file|
              file << "#{(link.to_s.split('/', 4))[3]}\n"
              $log.info("Discovered: #{(link.to_s.split('/', 4))[3]}")
            end
            progressbar.increment unless options.config[:quiet]
          end
        end
      end
    end
    end_time = Time.now
    timer = (end_time - beginning_time)*1000
    $log.info("Scour finished in #{timer * 60} minutes")
  end
end


