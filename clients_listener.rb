require './client_server.rb'
require 'socket'

class ClientsListener
  attr_reader :socket_address, :socket_port, :active_client_servers, :stopped

  def initialize(socket_address, socket_port)
    @socket_address = socket_address
    @socket_port = socket_port
    @active_client_servers = []
    @stopped = false
  end

  def start
    server_socket = TCPServer.open(socket_address, socket_port)
    print("Server started. Listening on #{socket_address}:#{socket_port}...\n")

    while !stopped do
      client_connection = server_socket.accept
      handle_client(client_connection)
    end

    server_socket.close
  end

  def stop
    @stopped = true
    active_client_servers.each do |server|
      server.stop
    end
    true
  end

  def handle_client(client_connection)
    server = ClientServer.new(client_connection)
    active_client_servers << server
    Thread.new do
      server.serve_client
      active_client_servers.delete(client_connection)
    end
  end
end
