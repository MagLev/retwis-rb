# Rack middleware to turn Gprof on/off.  This is just a sketch that samples
# for a given number of HTTP transactions.  You can modify the start/stop
# logic to suit your scenario.  E.g., you could have special URLs
# /start-profiling and /stop-profiling that were handled by this class, and
# then dump the report by /print-gprof-report.

class MagLevGprofWrapper

  attr_reader :count

  # Initialize the Gprof wrapper.  This calculates the sampling rate,
  # creates a profiler instance (turned off) and stores it in
  # @gprof_monitor
  def initialize(app)
    @app = app
    @count = 0

    # Hard-coded sample:
    sample_interval_ns = 100_000

    # Or, you could use your expected sample time and have the system
    # figure out an appropriate sampling rate. E.g., if an unprofiled run
    # takes 10 seconds of CPU time, then the following calculates the
    # appropriate sample rate.
    #
    #    unprofiled_cputime_seconds = 10
    #    sample_interval_ns = Maglev::Gprof.compute_interval(unprofiled_cputime_seconds)

    @gprof_monitor = Maglev::Gprof.create(sample_interval_ns)
  end

  def call(env)
    @count += 1
    puts "-- @count #{@count}" if @count % 50 == 0
    manage_profiling(env)
    status, headers, body = @app.call env
    [status, headers, body]
  end

  # Decide when to turn profiling on / off.  The current code does not use
  # the Rack environment, but you could get fancy and turn it on the first
  # time the REQUEST_PATH was some value, and turn it off at "/logout" etc.
  #
  # This version simply turns it on / off at hard coded values of 10..500
  def manage_profiling(env)
    start_profiling if @count == 10
    if @count == 500
      stop_profiling
      save_report
    end
  end

  def start_profiling
    unless @gprof_monitor.nil?
      puts "-- Start profiling at HTTP request #{@count}."
      @gprof_monitor.resume_sampling
    end
  end

  def stop_profiling
    unless @gprof_monitor.nil?
      puts "-- Stop profiling at HTTP request #{@count}."
      @gprof_monitor.suspend_sampling
    end
  end

  def save_report
    unless @gprof_monitor.nil?
      puts "gprof_monitor #{@gprof_monitor.inspect}"
      s = @gprof_monitor.stop_and_report
      File.open("./log/gprof-#{$$}.out", "w+") { |f| f.puts(s) }
      @gprof_monitor = nil
    end
  end
end
