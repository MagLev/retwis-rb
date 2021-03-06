MagLev Retwis-RB
================

An example Twitter application using MagLev as the database.  This example
is forked from [Daniel Lucraft's repository](http://github.com/danlucraft/retwis-rb).

Requirements
------------

* MagLev
* Sinatra, Rack: maglev-gem install sinatra

If you also want to run against MRI/Redis, see README-orig.md

* Ruby
* Redis: http://code.google.com/p/redis/
* Sinatra, Rack: sudo gem install sinatra

Starting Application
--------------------

The Rakefile has tasks to run and initialize test data for both MRI and
MagLev.  To run the MagLev demo, make sure the MagLev server is running,
then:

    $ rake maglev:run

If you want to create some random users and have them follow each other,
you can do:

    $ rake maglev:signup

There are similar tasks for MRI, use rake -T to list them.


Changes from Original
---------------------

This is a summary of the changes from the original project to make it work
under MagLev.  The views/, public/ and app.rb are unchanged, or have minor
changes to support switching between MRI and MagLev (i.e., un-substantive
changes only).

Functional Changes:

* `domain-maglev.rb`: Re-wrote the domain model to use MagLev as the backing
  store rather than Redis.  This is the bulk of the changes needed to make
  the demo run under MagLev.  The main change is to replace Redis key/value
  lookups, with instance variables.
* `etc/txn_wrapper.rb`: Added Rack middleware to wrap each http request in a
  maglev transaction.
* `etc/setup.rb`: A "migration"-like file to commit the code and initialize
  the persistent collections.

Non-functional Changes:

* Added a `Rakefile` to make it easy to run either the MRI version or the
  MagLev version.
* The html title, headings and descriptive text in the footer are sensitive
  to whether MagLev or MRI is running the app.
* Removed what appears to be debug cruft from the MRI version.
* `etc/signup_and_follow.rb`: A script to setup a bunch of users and
  followers.  Can be run by both MRI and MagLev.

Performance Notes
-----------------

Sinatra uses Tilt to cache pre-compiled erb templates for the views.  A
side-effect of the way Tilt currently caches the templates, causes six to
eight new, unique symbols to be generated per (rendered) HTTP request.  In
some of my performance testing, Tilt was generating a thousand symbols a
second.  Since MagLev is a shared, distributed object system, those symbols
must be coordinated with all VMs, and are never garbage collected.  This
puts a big strain on the Symbol system and causes intermittent pauses in
the application (1-3 seconds, or so).  MagLev runs better without the Tilt
caching.

Since the problem really only manifests in development mode (where all
cached items are essentially thrown away for each request), you can run in
production mode to avoid the problem.  `maglev.ru` runs in production mode.

License
-------

MIT
