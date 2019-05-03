require './client_server.rb'

describe ClientServer do
  class TestJob
    def perform(_first_param, _second_param)
      'result'
    end
  end

  let!(:server_socket) { TCPServer.open('localhost', 2001) }
  let!(:connection) do
    TCPSocket.new('localhost', 2001)
    server_socket.accept
  end

  after do
    connection.close
    server_socket.close
  end

  let(:client_server) { described_class.new(connection) }

  describe '#serve_client' do
    describe '#handle_command' do
      subject { client_server.handle_command(command) }

      describe 'perform_now' do
        let(:command) { 'perform_now TestJob first_param second_param' }

        it 'calls the perform method on the job class' do
          expect_any_instance_of(TestJob).to receive(:perform).with('first_param', 'second_param')

          subject
        end

        it 'outputs the job result in the connection' do
          expect(connection).to receive(:print).with(/result/)

          subject
        end
      end

      describe 'perform_later' do
        let(:command) { 'perform_later TestJob' }

        it 'enqueues a job to the queue' do
          expect {
            subject
          }.to change($jobs, :size).by(1)
          enqueued_job = $jobs.pop
          expect(enqueued_job.class_name).to eq('TestJob')
        end

        it 'outputs the job id in the connection' do
          expect(connection).to receive(:print).exactly(:once).with(satisfy { |param|
            expect(param).to eq($jobs.pop.id)
          })

          subject
        end
      end

      describe 'perform_in' do
        let(:command) { 'perform_later TestJob' }

        it 'enqueues a job to the queue' do
          expect {
            subject
          }.to change($jobs, :size).by(1)
          enqueued_job = $jobs.pop
          expect(enqueued_job.class_name).to eq('TestJob')
        end

        it 'outputs the job id in the connection' do
          expect(connection).to receive(:print).exactly(:once).with(satisfy { |param|
            expect(param).to eq($jobs.pop.id)
          })

          subject
        end
      end
    end
  end
end
