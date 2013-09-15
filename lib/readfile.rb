class ReadFile
  attr_accessor :lines
  def initialize( options )
    @lines = Hash.new
    @options = options
  end
  def open

    $log.info("Reading scour.dat")

    File.open("scour.dat", "r").each_line do |line|
      @lines[line] = 1
    end

    msg = "Read #{@lines.keys.count} lines from dat file\n"

    #puts msg unless @options.config[:quiet]
    $log.info(msg)
  end
end
