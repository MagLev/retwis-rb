require 'rake/clean'

CLEAN.include('log/*', 'nohup.out', '*~', 'jmeter.log')

task :default => :'maglev:run'

directory 'log'

MAGLEV_HOME = ENV['MAGLEV_HOME']

# Tasks in the :maglev namespace setup and run a single instance of the
# MagLev VM using WEBrick to serve the pages.
namespace :maglev do
  desc "Commit code, setup db and run app with WEBrick"
  task :run => [:commit, :initdb] do
    sh %{ #{MAGLEV_HOME}/bin/rackup --port 4567 maglev.ru }
  end

  desc "Create a bunch of users, have them follow each other; data stored in maglev stone."
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

# Tasks in the :mri namespace setup and run a single instance of the MRI
# VM, using whatever default server you have installed (thin, mongrel,
# etc.).  You need to manually manage the Redis server and ensure that it
# is running before running these tasks.
namespace :mri do
  desc "Run the sinatra app with mri (make sure redis is running first)."
  task :run do
    sh %{ ruby app.rb }
  end

  desc "Create a bunch of users, have them follow each other; data stored in Redis"
  task :signup do
    sh %{ ruby etc/signup_and_follow.rb }
  end
end

# Tasks in the :perf namespace create and manage a carefully configured
# stone, and run MagLev against that stone so that we can do some
# performance analysis.
namespace :perf do
  PERF_CONF  = File.join(File.dirname(__FILE__), "etc", "perf.conf")
  PERF_STONE = "perf"

  task :env => 'log' do
    # Setup the environment for the :perf tasks.
    # If STONENAME is set, maglev-ruby does NOT set GEMSTONE_SYS_CONF or
    # GEMSTONE_GLOBAL_DIR We pick up ./gem.conf for the VMs, and the stone
    # is already configured with ./perf/perf.conf
    ENV['STONENAME'] = PERF_STONE
    ENV['GEMSTONE_GLOBAL_DIR'] = MAGLEV_HOME
  end

  desc "Run app.rb with MagLev + WEBrick on the perf stone."
  task :run => :env do
    sh %{ #{MAGLEV_HOME}/bin/rackup --port 4567 maglev.ru }
  end

  desc "Commit and setup test data to the perf stone."
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

  desc "Start statmonitor on the perf stone (waits)."
  task :statmonitor => :env do
    out = File.join(File.dirname(__FILE__), "log", "statmonitor-#{$$}")
    smon = File.join(MAGLEV_HOME, "gemstone", "bin", "statmonitor")
    # -A:    Collects system stats
    # -i 1:  Sample every second
    # -u 5:  Write file every 5 seconds
    # -f x:  Write output to file named x
    puts "Starting statmonitor on #{PERF_STONE}.  Saving data to #{out}"
    sh %{ #{smon} #{PERF_STONE} -A -i 1 -u 5 -f #{out} }
  end

  desc "Start VSD (waits)."
  task :vsd do
    vsd = File.join(MAGLEV_HOME, "gemstone", "bin", "vsd")
    sh %{ #{vsd} }
  end

  desc "Start MagLev SCGI servers running; default starts one server.
        If the multi parameter is given, multiple servers are started.
        If the gprof parameter is given, one server is started using etc/gprof_wrapper.rb.
        Only one of gprof / multi is honored."
  task :scgi, :param, :needs => :env do |t, args|
    running = Dir.glob('rack-*.pid')
    if running.size > 0
      puts "You have running rack instances, stop them, delete #{running.inspect} and retry."
      exit
    end
    p args

    if args.param == 'multi'
      2.times do |i|
        port = "300#{i}"
        sh %{ nohup #{MAGLEV_HOME}/bin/rackup --server SCGI --pid rack-#{port}.pid --port #{port} maglev.ru & }
      end
    else
      conf = (args.param == 'gprof') ? 'gprof.ru' : 'maglev.ru'
      port = 3000
      sh %{ #{MAGLEV_HOME}/bin/rackup --server SCGI --pid rack-#{port} --port #{port} #{conf} }
    end
  end

  desc "Start the lighttpd server using SCGI to connect to MagLev."
  task :httpd, :multi, :needs => 'log' do |t, args|
    p args.multi
    conf = args.multi ? 'etc/lighttpd-multi.conf' : 'etc/lighttpd.conf'
    puts "CONF: #{conf}"
    rm_f ['log/error.log', 'log/access.log']
    sh %{ lighttpd -D -f #{conf} }
  end

  desc "kill SCGI apps named in rack-*.pid"
  task :killscgi do
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

  desc "Show processes listening on ports 300?"
  task :list do
    sh %{ netstat -anf inet | grep 300 ; true }
  end
end
