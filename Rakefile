task :default => :'mri:run'

namespace :mri do
  desc "Run the sinatra app with mri (make sure redis is running first)."
  task :run do
    sh %{ ruby app.rb }
  end

  desc "Create a bunch of users, have them follow each other"
  task :signup do
    sh %{ ruby etc/signup_and_follow.rb }
  end
end
