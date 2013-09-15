class ReadFile
  attr_accessor :lines
  def initialize( options )
    @lines = []
    @options = options
  end
  def open

    $log.info("Reading scour.dat")

    File.open("scour.dat", "r").each_line do |line|
      @lines << line
    end

    msg = "Read #{@lines.count} lines from dat file\n"
    msg << "De-duping... #{@lines.uniq.count} remaining\n"

    puts msg unless @options.config[:quiet]
    $log.info(msg)
  end
end
