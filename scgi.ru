# This uses a Rack SCGI handler to listen for SCGI requests.
#   Rack::Handler::SCGI takes :Host and :Port and :Socket options

require 'app'

Rack::Builder.new do
  if defined? Maglev
    Rack::Handler::SCGI.run(Sinatra::Application, :Host=> 'localhost', :Port => '3000')
  else
    # MRI by default on my Mac picks an IPV6 localhost:4567 socket.  The
    # lighttpd scgi plugin does not handle ipv6 (though lighttpd supports
    # ipv6)
    require 'socket'
    sock = TCPServer.new('127.0.0.1', 3000)
    # puts "PASSING SOCKET: #{sock.inspect}"
    Rack::Handler::SCGI.run(Sinatra::Application, :Socket => sock)
  end
end
