task :default => :'mri:run'

namespace :maglev do
  desc "Commit code, setup db and run app"
  task :run => [:commit, :initdb] do
    sh %{ maglev-ruby app.rb }
  end

  desc "Create a bunch of users, have them follow each other."
  task :signup => [:commit, :initdb] do
    sh %{ maglev-ruby -Mcommit etc/signup_and_follow.rb }
  end

  desc "Initialize the db, if not already initialized (may be forced)."
  task :initdb, :force do |t, args|
    sh %{ maglev-ruby -Mcommit etc/setup.rb #{args.force} }
  end

  desc "Commit the domain.rb code to the repository"
  task :commit do
    sh %{ maglev-ruby -Mcommit domain-maglev.rb }
  end
end

namespace :mri do
  desc "Run the sinatra app with mri (make sure redis is running first)."
  task :run do
    sh %{ ruby app.rb }
  end

  desc "Create a bunch of users, have them follow each other."
  task :signup do
    sh %{ ruby etc/signup_and_follow.rb }
  end
end
