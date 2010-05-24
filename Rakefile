require 'rake/clean'

CLEAN.include 'statmonitor*.out'

task :default => :'mri:run'

directory 'log'

MAGLEV_HOME = ENV['MAGLEV_HOME']
PERF_STONE = "perf"

task :env do
  # Setup the environment for the :perf tasks.
  # If STONENAME is set, maglev-ruby does NOT set GEMSTONE_SYS_CONF or
  # GEMSTONE_GLOBAL_DIR We pick up ./gem.conf for the VMs, and the stone is
  # already configured with ./perf/perf.conf
  ENV['STONENAME'] = PERF_STONE
  ENV['GEMSTONE_GLOBAL_DIR'] = MAGLEV_HOME
end

namespace :maglev do
  desc "Commit code, setup db and run app with WEBrick"
  task :run => [:commit, :initdb] do
    sh %{ #{MAGLEV_HOME}/bin/rackup --port 4567 maglev.ru }
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
  PERF_CONF  = File.join(File.dirname(__FILE__), "perf", "perf.conf")

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

  desc "Start statmonitor (waits...)"
  task :statmonitor => :env do
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
    vsd = File.join(MAGLEV_HOME, "gemstone", "bin", "vsd")
    sh %{ #{vsd} }
  end
end

# Run the app against lighttpd talking SCGI to MagLev
namespace :scgi do
  desc "Show processes listening on ports 300?"
  task :list do
    sh %{ netstat -anf inet | grep 300 ; true }
  end

  desc "Rm the log files and start the lighttpd server"
  task :server => 'log' do
    rm_f ['log/error.log', 'log/access.log']
    sh 'lighttpd -D -f perf/lighttpd.conf '
  end

  desc "Run MagLev on the Sinatra SCGI app"
  task :app => :env do
    sh "#{MAGLEV_HOME}/bin/rackup --server SCGI --port 3000 maglev.ru"
  end

  desc "kill SCGI apps named in rack-*.pid"
  task :killapps do
    pid = nil
    pid_files = Dir.glob('rack-*.pid')
    pid_files.each do |pid_file|
      begin
        pid = File.readlines(pid_file)
        sh %{ kill #{pid} }
      rescue
        puts "Failed on file #{pid_file}  pid #{pid}"
      ensure
        rm_f pid_file
      end
    end
  end

  task :pbm => :env do
    sh "nohup echo STONENAME $STONENAME GGD $GEMSTONE_GLOBAL_DIR &"
    port = 3000
    sh "nohup #{MAGLEV_HOME}/bin/rackup --server SCGI --pid rack-#{port}.pid --port #{port} maglev.ru &"
  end
  desc "Run multiple MagLev servers on the Sinatra SCGI app"

  desc "Rm the log files and start the lighttpd server for multi servers"
  task :servers => 'log' do
    rm_f ['log/error.log', 'log/access.log']
    sh 'lighttpd -D -f perf/lighttpd-multi.conf '
  end


  task :apps => :env do
    running = Dir.glob('rack-*.pid')
    if running.size > 0
      puts "You have running rack instances, clear them out and delete #{running.inspect}"
    else
      2.times do |i|
        port = "300#{i}"
        sh "nohup #{MAGLEV_HOME}/bin/rackup --server SCGI --pid rack-#{port}.pid --port #{port} maglev.ru &"
      end
    end
  end
end
