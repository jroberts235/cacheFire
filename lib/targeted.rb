def run_targeted(executor, ratio, threads, h, url, linkPool, options)
  #raise "Targeted mode requires that varnish be installed locally" unless File.exist?('/usr/bin/varnishstat')

  progressbar = ProgressBar.create(:format => '%a %w',
                                   :starting_at => 0,
                                   :total => 100,
                                   :smoothing => 0.8) unless options.config[:quiet]

  tasks = [] # array to track threads
  linkPool.calc_ratio

  until linkPool.ratio >= ratio do
    threads.times do
      task = FutureTask.new(Job.new(h, url, linkPool, options))
      executor.execute(task)

      tasks << task
    end
    progressbar.progress= linkPool.ratio unless options.config[:quiet]

    if linkPool.pool.count < threads
      linkPool.reload
    end

    linkPool.calc_ratio
 
    # wait for all threads to complete
    tasks.each do |t|
      t.get
    end
  end
end
