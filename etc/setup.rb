# This file is called by the Rakefile, and serves a similar function as a
# database migration file.  Creates empty, persistent collections for the
# timeline and users.

# If the "force" flag is sent, then we force resetting of the application
# data.
force = ARGV[0] == 'force'

[:user_by_name, :user_by_id].each do |key|
  if force || !Maglev::PERSISTENT_ROOT.key?(key)
    puts "-- Creating empty Hash for #{key}"
    Maglev::PERSISTENT_ROOT[key] = {}
  end
end

[:timeline, :users].each do |key|
  if force || ! Maglev::PERSISTENT_ROOT.key?(key)
    puts "-- Creating empty Array for #{key}"
    Maglev::PERSISTENT_ROOT[key] = []
  end
end

