class ReadFile
  attr_accessor :lines
  def initialize
    @lines = []
  end
  def open

    $log.info("Reading scour.dat")

    File.open("scour.dat", "r").each_line do |line|
      @lines << line
    end

    msg = "Read #{@lines.count} lines from dat file\n"
    msg << "De-duping... #{@lines.uniq.count} remaining\n"

    puts msg
    $log.info(msg)
  end
end
