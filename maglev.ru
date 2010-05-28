require 'etc/txn_wrapper'
require 'app'

use MagLevTransactionWrapper

run Sinatra::Application
