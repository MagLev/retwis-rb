Notes on Performance Analysis
=============================

This branch has some extra config and support to do performance analysis on
MagLev.

The idea is to create and run against a separate stone, "perf".  The stone
is configured according to `perf/perf.conf`.  The VMs will run against the
configuration in `./gem.conf`.

Requirements
------------

Install sinatra, rack and scgi gems for MagLev:

    $ maglev-gem install rack sinatra scgi

You'll also have to install Lighttpd.

Setup
-----

To create the performance stone, setup its config, and kick it off:

    $ rake perf:createstone

After that, you can just cd to maglev home and manage starting/stoping the
stone from there.

Once the stone is created, you can initialize it with the app code and
initial test data by doing:

    $ rake perf:init

Then, to run the application you can do:

    $ rake perf:run

To start a statmonitor against the perf stone and VMs:

    $ rake perf:statmonitor

Typically, you'd start statmonitor before you run a load on the system.
statmonitor will write to `./statmonitor-<pid>.out`.  To analyze the stats,
you can run VSD:

    $ rake perf:vsd


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
