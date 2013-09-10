require 'mixlib/cli'

class Options
  include Mixlib::CLI

  option :url,
    :short => "-u URL",
    :long => "--url URL",
    :description => "URL to access",
    :required => true

  option :report,
    :short => "-R",
    :long => "--Report",
    :boolean => true,
    :description => "Count and report the number of links in scour.dat",
    :default => false

  option :threads,
    :short => "-t threads",
    :long => "--threads threads",
    :description => "Number of parallel threads to use",
    :default => 1

  option :scour,
    :short => "-s",
    :long => "--scour",
    :boolean => true,
    :description => "scour URL and build data file?",
    :default => false

  option :retrieve,
    :short => "-r",
    :long => "--retrieve",
    :boolean => true,
    :description => "Read the data from scour.dat and pick random URLs to hit",
    :default => false

  option :pages,
    :short => "-p pages",
    :long => "--pages pages",
    :description => "Number of pages to retrieve",
    :default => 100

  option :help,
    :long => "--help",
    :short => "-h",
    :description => "Show this message",
    :on => :tail,
    :show_options => true,
    :boolean => true,
    :exit => 0
end
