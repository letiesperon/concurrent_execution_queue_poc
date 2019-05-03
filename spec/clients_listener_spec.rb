require './clients_listener.rb'

describe ClientsListener do
  let(:socket_address) { 'localhost' }
  let(:socket_port) { 2001 }

  before do
    allow_any_instance_of(IO).to receive(:print)
  end

  describe '#handle_client' do
    let!(:server_socket) { TCPServer.open('localhost', 2001) }
    let!(:connection) do
      TCPSocket.new('localhost', 2001)
      server_socket.accept
    end

    let(:client_listener) { described_class.new(socket_address, socket_port) }
    let(:subject) { client_listener.handle_client(connection) }

    before do
      allow_any_instance_of(ClientServer).to receive(:serve_client).and_return(true)
    end

    after do
      connection.close
      server_socket.close
    end

    it 'initializes a new client server thread' do
      expect(Thread).to receive(:new).and_yield.and_return(Class.new { def join; end }.new)
      expect(ClientServer).to receive(:new).with(an_instance_of(TCPSocket)).and_call_original

      subject
    end

    it 'adds the connection to the thread' do
      expect {
        subject
      }.to change(client_listener.active_client_servers, :size).by(1)
    end
  end

  describe '#stop' do
    let(:client_listener) { described_class.new(socket_address, socket_port) }

    it 'returns true' do
      expect(client_listener.stop).to be
    end

    it 'sets stopped in true' do
      client_listener.stop

      expect(client_listener.stopped).to be
    end
  end
end
