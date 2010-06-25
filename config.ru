require "app"

# For parity with maglev.ru
set :environment, :production

run Sinatra::Application
