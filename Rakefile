require 'rake/clean'

CLEAN.include 'statmonitor*.out'

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

# The :perf namespace defines tasks that create and manage a carefully
# configured stone, and tasks to run against that stone so that we can do
# some performance analysis.
namespace :perf do
  MAGLEV_HOME = ENV['MAGLEV_HOME']
  PERF_STONE = "perf"
  PERF_CONF  = File.join(File.dirname(__FILE__), "perf", "perf.conf")

  task :env do
    # Setup the environment for these tasks.  If STONENAME is set,
    # maglev-ruby does NOT set GEMSTONE_SYS_CONF or GEMSTONE_GLOBAL_DIR We
    # pick up ./gem.conf for the VMs, and the stone is already configured
    # with ./perf/perf.conf
    ENV['STONENAME'] = PERF_STONE
    ENV['GEMSTONE_GLOBAL_DIR'] = MAGLEV_HOME
  end

  desc "Run the app against the perf stone"
  task :run => :env do
    sh %{ maglev-ruby app.rb }
  end

  desc "Commit and setup test data"
  task :init => :env do |t, args|
    sh %{ maglev-ruby -Mcommit domain-maglev.rb }
    sh %{ maglev-ruby -Mcommit etc/setup.rb }
    sh %{ maglev-ruby -Mcommit etc/signup_and_follow.rb }
  end

  desc "Create performance stone named '#{PERF_STONE}'"
  task :createstone do
    cd(MAGLEV_HOME) do
      perf_conf = "etc/conf.d/#{PERF_STONE}.conf"
      rm_f perf_conf  # Remove if leftover from previous run

      sh %{ rake stone:create[#{PERF_STONE}] }
      rm_f perf_conf  # Remove to ensure we replace it
      cp PERF_CONF, perf_conf

      sh %{ rake #{PERF_STONE}:start }
    end
  end

  task :pbm do
    puts "PERF_CONF: '#{PERF_CONF}'"
    cd(MAGLEV_HOME) do
      sh %{ ls }
      sh %{ ls etc/conf.d }
    end
  end

  desc "Start statmonitor (waits...)"
  task :statmonitor do
    out = File.join(File.dirname(__FILE__), "statmonitor-#{$$}")
    smon = File.join(MAGLEV_HOME, "gemstone", "bin", "statmonitor")
    # -A:    Collects system stats
    # -i 1:  Sample every second
    # -u 5:  Write file every 5 seconds
    # -f x:  Write output to file named x
    puts "Starting statmonitor.  Saving data to #{out}"
    sh %{ #{smon} #{PERF_STONE} -A -i 1 -u 5 -f #{out} }
  end

  desc "Start VSD (waits...)"
  task :vsd do
    vsd = File.join(ENV['MAGLEV_HOME'], "gemstone", "bin", "vsd")
    sh %{ #{vsd} }
  end
end
