def run_standard(executor, links, threads, h, url, linkPool, options, stats)
    puts "Getting #{links} links using #{threads} thread(s)."  unless options.config[:quiet]

    progressbar = ProgressBar.create(:format => '%a <%B> %p%% %t',
                                     :starting_at => 0,
                                     :total => links,
                                     :smoothing => 0.8
                                     ) unless options.config[:quiet]

    tasks = [] # array to track threads

    (links / threads).times do
        if linkPool.pool.count >= 1 # stop if we run out of links
            threads.times do
                path = linkPool.fetch
                raise "No path returned from linkPool.fetch!" if path == nil

                task = FutureTask.new(Job.new(h, url, linkPool, options, stats, path))
                executor.execute(task)
                tasks << task

                linkPool.remove(path) if options.config[:uniq]
            end
        end
        
        # don't run out of links to give jobs
        if linkPool.count < threads
            linkPool.reload
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
        puts "Cache-Hits:     #{stats.hits}"
        puts "Cache-Miss:     #{stats.total - stats.hits}"
        puts "Hit/Miss Ratio: #{stats.ratio}%"
        puts "Errors:         #{stats.errors.count}"
        puts "Hit Avg:        #{(stats.hit_avg).round(3)}s"
        puts "Miss Avg:       #{(stats.miss_avg.round(3))}s"
    end
end
