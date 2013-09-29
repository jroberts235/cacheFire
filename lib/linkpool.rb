$LOAD_PATH << './'
require 'readfile.rb'
require 'rest-client'
require 'redis'


class LinkPool
    attr_accessor(:count, :pool)
    def initialize(log, options, statsd)

            @log = log
          @count = 0
        @options = options
            @url = options.config[:url]
           @pool = ThreadSafe::Hash.new
         @statsd = statsd

    end

    def fetch
        wesley = @pool.keys.sample 
        return if wesley == nil
        path = wesley.dup 
        path.gsub!(/^/, '/') unless path.start_with?('/') 
        return path
    end

    def read
        if @options.config[:redis] # get paths from local redis
            redis = Redis.new
            raise "Cannot reach local Redis server!" if redis == false
            @log.info(redis.inspect)
            redis.keys.each { |k| @pool[k] = 1 }
        else # read file and populate the links Hash
            r = ReadFile.new(@log, @options)
            r.open
            @pool = r.lines
        end
    end

    def count
        @pool.keys.count 
    end

    def reload
        @log.info("Reloading paths from #{options.config[:filename]}")
        self.read
    end

    def remove(path)
        @log.info("Removing: #{path}")
        @pool.delete(path)
        @log.info("Paths remaining: #{self.count}")
    end

    def purge # "ban" really
              fqdn = (@options.config[:url].split(/\/\//, 2))[1] # get fqsn from URL
              host = (fqdn.split(/\./, 3))[0]                    # get host from fqdn
              sub  = (fqdn.split(/\./, 3))[1]                    # get subdomain from host
        varnishadm = "/usr/local/opt/varnish/bin/varnishadm"
            secret = "/Users/jroberts/ruby/cacheFire/secret"

        @log.info("Banning all current links on #{host}")
        raise "varnishadm can not be found!" unless File.exist?(varnishadm)
        system("#{varnishadm} -T #{fqdn}:6082 -S #{secret} \"ban.url .\"")

        if $? == 0
            @statsd.increment("#{host}.#{sub}.varnish.cacheFire.ban", 1)
        else
            raise "Banning operation failed!"
        end
    end
end
