def run_targeted(log, executor, threads, h, url, linkPool, options, stats)

    msg = "Getting #{linkPool.count} links using #{threads} thread(s)." 
    puts msg unless options.config[:quiet]
    log.info(msg)

    # Ban all links in the cache
    if options.config[:flush]
        puts 'Banning all links currently in cache'
        linkPool.purge
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

              task = FutureTask.new(Job.new(log, h, url, linkPool, options, stats, path))
              executor.execute(task)
              tasks << task
              linkPool.remove(path) 
              progressbar.progress = linkPool.count unless options.config[:quiet]
            end
        end
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
