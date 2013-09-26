def run_targeted(executor, threads, h, url, linkPool, options, stats)
  puts "Getting #{linkPool.count} links using #{threads} thread(s)." unless options.config[:quiet]

  progressbar = ProgressBar.create(:format => '%a <%B> %p%% %t',
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
      end
    end

    # wait for all threads to complete
    tasks.each do |t|
      progressbar.increment unless options.config[:quiet]
      t.get
    end
  end
  # finish with some stats
  unless options.config[:quiet]
    stats.calc_ratio
    puts "\n"
    puts "Errors:         #{stats.errors.count}"
    puts "Hit Avg:        #{(stats.hit_avg).round(3)}s"
    puts "Miss Avg:       #{(stats.miss_avg.round(3))}s"
  end
end
