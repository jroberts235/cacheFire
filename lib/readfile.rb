class ReadFile
  attr_accessor :lines
  def initialize( options )
    @lines = Hash.new
    @options = options
  end
  def open
    filename = @options.config[:file]

    $log.info("Reading scour.dat")

    File.open(filename, "r").each_line do |line|
      @lines[line.chomp] = 1
    end

    msg = "Read #{@lines.keys.count} lines from #{filename}\n"

    $log.info(msg)
  end
end
