require 'etc/txn_wrapper'
require 'app'

set :environment, :production

use MagLevTransactionWrapper

run Sinatra::Application
