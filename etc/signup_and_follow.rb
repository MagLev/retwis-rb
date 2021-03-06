# This script creates N twitter users and then has each one follow
# NUM_FOLLOWEES other twitter users.

require 'benchmark'
require 'digest/md5'

# Maglev does not need to require domain-maglev.rb, since that should have
# previously been committed to the repository.  Likewise, we do not want to
# load rubyredis since MagLev doesn't use it.
unless defined? Maglev
  require 'rubyredis'
  require 'domain'

  def redis
    $redis ||= RedisClient.new(:timeout => nil)
  end
end

NUM_FOLLOWEES = 10  # number of users each user follows
N = 1_000           # The number of users

# Create and signup +n+ users.  Each user will be named "testuser<n>" and
# will have a password of "password<n>".
def signup(n=N)
  puts "-- Signup #{n} Users"
  n.times do |i|
    User.create("testuser#{i}", "password#{i}")
  end
end

# Have each user follow NUM_FOLLOWEES other random users
def follow(num_users=N)
  num_users.times do |n|
    user = User.find_by_username("testuser#{n}")
    NUM_FOLLOWEES.times do
      f = User.find_by_username("testuser#{rand(num_users)}")
      user.follow(f)
    end
  end
end

Benchmark.bm do |r|
  r.report("signup") { signup }
  r.report("follow") { follow }
end

