~ cacheFire ~

A cache heater/load gen tool written in jruby and is multithreaded for better performance.
There are three modes to run the app in, "Scour", "Retrieve" and "Targetd Rerieve".  


Scour:  uses a gem called Anenome to crawl the provided URL and generate a file with *all* of the links on the site.  This can be a very long process but it is multi-threaded (default: = 1) so you should definately make use of the "-t, --threads" option.  You can manipulate the scour.dat file by hand to remove any link that you want to skip for what ever reason but don't worry about duplicate entries, they're handled by the app.


Retreive:  opens the scour.dat file and picks random (see Caveats) links to hit.  The number of links to Get is set at runtime with the links option (-l, --links) and defaults to 100.  This uses the persistent/http gem so that all Gets are done over a single session. 


Targeted Retreive:  This mode Gets every link until the cache reaches the Hit/Miss ratio provided. While the other modes keep track of hit and miss stats, this mode gets that same info from Varnish itself vias the Mngmt API by calling the "varnishstats" command.  Because of this, varnishstats must be either installed locally or the caceFire needs to be run from the Varnish server itself.  This step does slow down execution a bit but not by so much that it's not worth using.


Running with "purge" option: This option causes every link to be pulled until it's a cache hit, then it's removed from the link pool.  This is valuable if you goal is to heat the entire cache evenly rather than just create load.  If using this option while doing a Targeted Retreive you will likely deplete the link pool before your target goal is complete.  To keep this from happening it will reload the scour.dat file when the link pool has exactly $threads left.  In a standard Retrieve run,  when the link pool is depleted all currenlty running job will end and the app will exit gracefully.


REQUIRES:  

jruby, java and the bundler gem.

INSTALL: 

rvm install jruby
git clone git@github.com:jroberts235/cacheFire.git
cd cacheFire ; bundler 

USAGE:

jruby ./cacheFire.rb -u http://YOUR.SITE -s             Scour the site and find all links
jruby ./cacheFire.rb -u http://YOUR.SITE -r -l 10000    Retrieve all links randomly 10000 times
jruby ./cacheFire.rb -u http://YOUR.SITE -r -p -T 85    Get very link until cache is 85% hot


Caveats:

"Random":  I am not sure how Rnd this really is.  I am using the array.sample method to pull links from the link pool and it works just fine for my purposes.  I you need something different please submit a pull request.

"Multi-Threaded Issues":  This is my first mutli-threaded application and I learned a lot by writing it.  I, no doubt, have made some newbie mistakes and missed optimizations that could make it better.  I welcome your comments and pull requests.  One problem that I KNOW exists is the the purge option.  Because the individual thread jobs themselves remove links from the shared Array,  errors will ocassionally be thrown, despite the inclusion of the thread-safe libray.
