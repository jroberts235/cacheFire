class ReadFile
    attr_accessor :lines

    def initialize(log, options)

            @log = log
          @lines = Hash.new
        @options = options

        raise "You can't specify both --redis and -f, --filename!" if @options.config[:redis]
    end

    def open
        filename = @options.config[:file]
        raise "File #{filename} cannot be found!" unless File.exists?(filename)
        @log.info("Reading #{filename}")

        File.open(filename, "r").each_line do |line|
            @lines[line.chomp] = 1
        end

        @log.info("Read #{@lines.keys.count} lines from #{filename}\n")
    end
end
