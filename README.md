MagLev Retwis-RB
================

An example Twitter application using MagLev as the database.  This example
is forked from Daniel Lucraft's (dan@fluentradical.com) version:
http://github.com/danlucraft/retwis-rb

For this checkin, there is no MagLev support, just adding Rakefile, new
readme and the etc/* files.

Requirements
------------

 * MagLev
 * Sinatra: sudo gem install sinatra

If you also want to run against MRI/Redis, see README-orig.md

 * Ruby
 * Redis: http://code.google.com/p/redis/

Starting Application
--------------------

Make sure the MagLev server is running, then:

    $ rake

If you want to create some random users and have them follow each other,
you can do (make sure redis is running):

    $ rake mri:signup

License
-------

MIT
