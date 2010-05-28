require 'app'
require 'etc/gprof_wrapper'
require 'etc/txn_wrapper'

use MagLevGprofWrapper
use MagLevTransactionWrapper

run Sinatra::Application
