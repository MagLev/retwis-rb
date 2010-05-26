require 'app'
require 'etc/gprof_wrapper'

use MagLevGprofWrapper

run Sinatra::Application
