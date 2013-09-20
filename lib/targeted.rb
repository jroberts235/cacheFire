def run_targeted(executor, ratio, threads, h, url, linkPool, options, stats)

  progressbar = ProgressBar.create(:format => '%a %w',
                                   :starting_at => 0,
                                   :total => 100,
                                   :smoothing => 0.8) unless options.config[:quiet]

  tasks = [] # array to track threads
  stats.calc_ratio

  until stats.ratio >= ratio do
    threads.times do
      task = FutureTask.new(Job.new(h, url, linkPool, options, stats))
      executor.execute(task)

      tasks << task
    end
    progressbar.progress= stats.ratio unless options.config[:quiet]

    if linkPool.pool.count < threads
      linkPool.reload
    end

    stats.calc_ratio
 
    # wait for all threads to complete
    tasks.each do |t|
      t.get
    end
  end
end
