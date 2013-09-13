cacheFire

A cache heater/load gen tool written in jruby which is multithreaded for better performance.

There are two modes to run the app in, "Scour" and "Retrieve".  Scour uses a gem called Anenome to crawl the provided URL and generate a file with *all* of the links on the site.  This can be a very long process but it is multi-threaded (default: = 1).  The second mode is the business end.  Retreive opens the scour.dat file and picks random links to hit.  The number of pages to Get is set at runtime with the pages option (-p, pages).  This uses the persistent/http gem so that all Gets are done over a single session. The defaul number of threads for both methods is 1 but can (should) be adjusted with the threads options (-t, --threads) 

REQUIRES:  

jruby and bundler (to install Gems via the Gemfile)

INSTALL: 

bundler Gemfile

USAGE:

jruby ./cacheFire.rb -u http://YOUR.SITE -s
jruby ./cacheFire.rb -u http://YOUR.SITE -r


