class ReadFile
  attr_accessor :lines
  def initialize( options )
    @lines = Hash.new
    @options = options
  end
  def open
    filename = @options.config[:file]

    raise "File #{filename} cannot be found!" unless File.exists?(filename)

    $log.info("Reading #{filename}")

    File.open(filename, "r").each_line do |line|
      @lines[line.chomp] = 1
    end

    $log("Read #{@lines.keys.count} lines from #{filename}\n")
  end
end
