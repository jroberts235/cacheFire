def run_standard(executor, links, threads, h, url, linkPool, options)
  progressbar = ProgressBar.create(:format => '%a <%B> %p%% %t',
                                   :starting_at => 0,
                                   :total => links,
                                   :smoothing => 0.8) unless options.config[:quiet]

  tasks = [] # array to track threads
  uri = @linkPool.pool.sample

  (links/threads).times do
    if linkPool.pool.count >= 1
      threads.times do
        task = FutureTask.new(Job.new(h, url, linkPool, options))
        executor.execute(task)
        tasks << task
        linkPool.total_incr
        progressbar.increment unless options.config[:quiet]
      end
    end

    # wait for all threads to complete
    tasks.each do |t|
      t.get
    end
   end

   # finish with some stats
   unless options.config[:quiet]
     linkPool.calc_ratio
     puts "\n"
     puts "Cache-Hits:     #{linkPool.hits}"
     puts "Cache-Miss:     #{linkPool.total - linkPool.hits}"
     puts "Hit/Miss Ratio: #{linkPool.ratio}%"
   end
end
