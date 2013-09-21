def run_targeted(executor, threads, h, url, linkPool, options, stats)
  puts "Heating cache to 100% using #{threads} thread(s)."  unless options.config[:quiet]

  progressbar = ProgressBar.create(:format => '%a %w',
                                   :starting_at => 0,
                                   :total => 100,
                                   :smoothing => 0.8) unless options.config[:quiet]

  tasks = [] # array to track threads
  total = linkPool.count
  raise "linkPool.count is 0" if total == 0

  # pull each link only once, then stop
  total.times do
    threads.times do
      path = linkPool.fetch
      raise "No path returned from linkPool.fetch" if path == nil

      task = FutureTask.new(Job.new(h, url, linkPool, options, stats, path))
      executor.execute(task)
      tasks << task
      linkPool.remove(path) 
    end
    progressbar.progress= stats.ratio unless options.config[:quiet]

    # wait for all threads to complete
    tasks.each do |t|
      t.get
    end
  end
end
