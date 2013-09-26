require 'mixlib/cli'

class Options
  include Mixlib::CLI

  option :url,
    :short => "-u URL",
    :long => "--url URL",
    :description => "URL to access (must include http://)",
    :required => true

  option :threads,
    :short => "-t number",
    :long => "--threads number",
    :description => "Number of parallel threads to use",
    :default => 1

  option :scour,
    :short => "-S",
    :long => "--scour",
    :boolean => true,
    :description => "scour URL and build data file?",
    :default => false

  option :depth,
    :short => "-d n",
    :long => "--depth n",
    :description => "Depth to scour to.",
    :default => nil

  option :targeted,
    :short => "-T",
    :long => "--targeted",
    :boolean => true,
    :description => "Pull every link once, thereby heating the cache 100%",
    :default => nil

  option :retrieve,
    :short => "-R",
    :long => "--retrieve",
    :boolean => true,
    :description => "Read the data from scour.dat and pick random URLs to hit",
    :default => false

  option :redis,
    :long => "--redis",
    :boolean => true,
    :description => "Use Redis as the input source instead of a file",
    :default => false

  option :links,
    :short => "-l number",
    :long => "--links number",
    :description => "Number of links to retrieve",
    :default => 100

  option :file,
    :short => "-f name",
    :long => "--file name",
    :description => "File name to use as the input source",
    :default => 'scour.dat'

  option :uniq,
    :long => "--uniq",
    :boolean => true,
    :description => "Get every link only once",
    :default => false

  option :purge,
    :long => "--purge",
    :description => "Purge the entire cache!!!",
    :boolean => true,
    :default => false
 
  option :port,
    :short => "-p number",
    :long => "--Port number",
    :description => "Port to connect to",
    :default => 80

  option :vhost,
    :short => "-v name",
    :long => "--vhost name",
    :description => "Name to set the HOST header to.",
    :default => nil

  option :quiet,
    :short => "-q",
    :long => "--quiet",
    :boolean => true,
    :description => "quit mode",
    :default => false

  option :help,
    :long => "--help",
    :short => "-h",
    :description => "Show this message",
    :on => :tail,
    :show_options => true,
    :boolean => true,
    :exit => 0
end
