require 'socket'

server = TCPServer.new('localhost', 2345)

flag = true

Thread.new {
  loop do
    if flag
      puts "cock"
    else
      puts "balls"
    end
    sleep 2
  end
}

loop do

  # Wait for a connection
  socket = server.accept
  STDERR.puts "Incoming Request"

  # Read the HTTP request. We know it's finished when we see a line with nothing but \r\n
  http_request = ""
  while (line = socket.gets) && (line != "\r\n")
    http_request += line
  end
  STDERR.puts http_request
  if http_request.match(/\/start/)
    flag = true
  elsif http_request.match(/\/stop/)
    flag = false
  end
  socket.close
end
