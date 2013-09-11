require 'mixlib/cli'

class Options
  include Mixlib::CLI

  option :url,
    :short => "-u URL",
    :long => "--url URL",
    :description => "URL to access (must include http://)",
    :required => true

  option :report,
    :short => "-R",
    :long => "--Report",
    :boolean => true,
    :description => "*NOT implemented* Count and report the number of links in scour.dat",
    :default => false

  option :threads,
    :short => "-t",
    :long => "--threads (# of threads)",
    :description => "Number of parallel threads to use",
    :default => 1

  option :purge,
    :short => "-P",
    :long => "--purge",
    :boolean => true,
    :description => "Purge links from pool after they report being a chache hit",
    :default => false

  option :target,
    :short => "-T",
    :long => "--target",
    :description => "Don't bother with page count, randomly load all pages until cache hit/miss ratio = value (default 75%)"

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
    :long => "--pages (# of pages)",
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
