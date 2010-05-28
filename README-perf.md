Notes on Performance Analysis
=============================

This branch has some extra config and support to do performance analysis on
MagLev.

The idea is to create and run against a separate stone, "perf".  The stone
is configured according to `etc/perf.conf`.  The VMs will run against the
configuration in `./gem.conf`.

Requirements
------------

Install sinatra, rack and scgi gems for MagLev:

    $ maglev-gem install rack sinatra scgi

Ensure you have Lighttpd installed.

You may want to edit base.rb in the Sinatra gem to turn off Tilt caching
(see performance note in README.md).

Setup
-----

To create the performance stone, setup its config, and kick it off:

    $ rake perf:createstone

Once the stone is created, you can initialize it with the app code and test
data by doing:

    $ rake perf:init

If you need to stop or restart the perf stone, just cd to $MAGLEV_HOME and
use the `perf:*` rake tasks:

    $ cd $MAGLEV_HOME
    $ rake perf:stop
    $ rake perf:start

etc.

Run Single VM with WEBrick
--------------------------

To run the application on MagLev with a single VM using WEBrick:

    $ rake perf:run

You can then hit [http://localhost:4567/](http://localhost:4567/) and login
as a testuser (test users were created during `rake perf:init`):

   User:     testuser0
   Password: password0

Run one VM using SCGI + lighttpd
--------------------------------

Make sure you've stopped any VMs running from `rake perf:run`, or
you'll get a socket connection error.

To start a single instance of MagLev listening on port 3000 for SCGI
connections, do:

    $ rake perf:scgi

Then, from a different shell, start up lighttpd:

    $ rake perf:httpd

You can then hit http://localhost:4567/ and login as a testuser (test users
were created during `rake perf:init`):

   User:     testuser0
   Password: password0


Run multiple VMs using SCGI + lighttpd
--------------------------------------

Make sure you've stopped any currently running VMs.

To start multiple instances of MagLev listening on port 300[0-n] for SCGI
connections, do:

    $ rake perf:scgi[multi]   # fires VMs in background

Then start up lighttpd:

    $ rake perf:httpd[multi]

Now hit http://localhost:4567/ and login as a testuser (test users were
created during `rake perf:init`):

   User:     testuser0
   Password: password0


To stop the SCGI processes represented by the `rack-3xxx.pid` files,
run:

    $ rake perf:killscgi

Performance Monitoring: Gprof
-----------------------------

The MagLev VM has a built-in method sampling profiler.  You can
programmatically start and stop the monitor.  It works by sampling the
stack at a configurable interval.  This shows which routines are getting
the most time, from a statistical point of view.

`etc/gprof_wrapper.tb` is Rack middleware to manage profiling.  The simple
implementation turns profiling on after 10 HTTP requests and turns it off
after 500.  You can easily modify the logic to your needs.  To run using
the simple profiler, use the `gprof.ru` rackup file.  The `perf:gprof`
target starts one MagLev VM with profiling enabled and listening on SCGI:

    $ rake perf:gprof   # start MagLev + SCGI + Gprof
    $ rake perf:httpd   # start lighttpd

    <send a bunch of HTTP requests to localhost:4567>

View the results in `log/gprof-<pid>.out`.

Performance Monitoring: Statmonitor
-----------------------------------

The MagLev processes all record statistics in real time to a shared memory
page (in the Shared Page Cache).  There are hundreds of statistics kept by
the various processes, and a few slots left for applications to write their
own stats.  These statistics can show you the number of commits and aborts
your VMs are doing, whether the Shared Page Cache is full, if/when disk
garbage collection occurs, number of objects/bytes read into/out-of the VM
etc.

To gain access to these statistics, you need to run the MagLev statmonitor
process.  This process connects to the Shared Page Cache, reads the
statistics at some interval (configurable), and writes the statistics to a
logfile for further analysis.

You need to make sure the statmonitor is running before whatever activity
you are interested in begins.  To start the statmonitor on the perf stone:

    $ rake perf:statmonitor

And then you can start loading your system (e.g., run JMeter using the
`etc/TweetLoop.jmx` file.  Statmonitor writes to
`./log/statmonitor-<pid>.out`.

After the run, use VSD to view the data:

    $ rake perf:vsd

And then load the `statmonitor-<pid>.out` file of interest.  VSD is a bit
funky, but shows a lot of useful data.

JMeter Load
-----------

There is a JMeter file in `perf/TweetLoop.jmx`.  This is a work in
progress.  It has three thread groups, one creates a bunch of accounts
(disabled by default), one sets up a bunch of followers (disabled by
default) and the final thread group logs in, and sends a bunch of tweets.
If you've already done the `rake perf:init`, then you already created the
users and have them following one another, so just the tweet loop is what I
run.   The load is not yet cranked up high, I'm just trying to get basic
performance issues resolved first, then we'll crank it up.

Lighttpd and SCGI
-----------------

Lighttpd supports both IPv4 and IPv6, but the Lighttpd SCGI plugin only
seems to handle IPv4 (at least on my Mac).  You may need to be careful,
especially running MRI on a Mac, to ensure that the Ruby processes open
IPv4 sockets for Lighttpd to connect to.
