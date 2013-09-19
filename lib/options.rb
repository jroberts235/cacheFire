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
    :short => "-s",
    :long => "--scour",
    :boolean => true,
    :description => "scour URL and build data file?",
    :default => false

  option :targeted,
    :short => "-T number",
    :long => "--targeted number",
    :description => "Pull links until the Hit/Miss ratio reaches the specified amnt",
    :default => nil

  option :retrieve,
    :short => "-r",
    :long => "--retrieve",
    :boolean => true,
    :description => "Read the data from scour.dat and pick random URLs to hit",
    :default => false

  option :links,
    :short => "-l number",
    :long => "--links number",
    :description => "Number of links to retrieve",
    :default => 100

  option :uniq,
    :long => "--uniq",
    :boolean => true,
    :description => "Get every link only once",
    :default => false

  option :purge,
    :long => "--purge",
    :description => "Purge the URI's in the scour.dat file",
    :boolean => true,
    :default => false
 
  option :port,
    :short => "-P number",
    :long => "--Port number",
    :description => "Port to connect to",
    :default => 80

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
