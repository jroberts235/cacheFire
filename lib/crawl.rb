require 'anemone'

class Crawl
  def initialize(url)
    links = []

    dataFile = File.new "scour.dat","w"
    dataFile.close

    progressbar = ProgressBar.create(:starting_at => 20,
                                      :total => nil)
    Anemone.crawl(url) do |anemone|
      anemone.threads = 15
      anemone.on_every_page do |page|
        (page.links).each do |link|
          unless links.include?(link) and link != nil
            links << link
            File.open('scour.dat', 'a') do |file|
              file << "#{(link.to_s.split('/', 4))[3]}\n"
            end
            progressbar.increment
          end
        end
      end
    end
  end
end
