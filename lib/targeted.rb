def run_targeted(executor, threads, h, url, linkPool, options, stats)
  puts "Getting #{linkPool.count} links using #{threads} thread(s)." unless options.config[:quiet]

  if options.config[:flush]
    raise "varnishadm not found!" unless File.exist?('/usr/bin/varnishadm')
    system('sudo varnishadm -T :6082 "ban.url ." -S /etc/varnish/secret')
    raise "Varnish ban did not succeed" unless $? == 1
    $log.info("Banned entire cache.")
  end

  progressbar = ProgressBar.create(:format => '%a <%B> %c %t',
                                   :title => "Links Remaining", 
                                   :starting_at => 0,
                                   :total => linkPool.count,
                                   :smoothing => 0.8) unless options.config[:quiet]

  tasks = [] # array to track threads
  total = linkPool.count
  raise "linkPool.count is 0" if total == 0

  # pull each link only once, then stop
  total.times do
    threads.times do
      if linkPool.count >= 1 # stop if we run out of links
        path = linkPool.fetch
        raise "No path returned from linkPool.fetch" if path == nil

        task = FutureTask.new(Job.new(h, url, linkPool, options, stats, path))
        executor.execute(task)
        tasks << task
        linkPool.remove(path) 
        progressbar.progress = linkPool.count unless options.config[:quiet]
      end
    end

    # wait for all threads to complete
    #tasks.each do |t|
    #  t.get
    #end
  end
  puts "executor shutdown"
  executor.shutdown() 

  # finish with some stats
  unless options.config[:quiet]
    stats.calc_ratio
    puts "\n"
    puts "Errors:         #{stats.errors.count}"
    puts "Hit Avg:        #{(stats.hit_avg).round(3)}s"
    puts "Miss Avg:       #{(stats.miss_avg.round(3))}s"
  end
end
