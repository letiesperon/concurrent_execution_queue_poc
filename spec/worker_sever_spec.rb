require './hello_world_job.rb'
require './hello_me_job.rb'
require './worker_server.rb'

describe WorkerServer do
  subject { described_class.new }

  describe '#start' do
    after do
      subject.stop
    end

    context 'when the jobs are valid' do
      before do
        $jobs = Queue.new
        $jobs.push(Job.new('HelloWorldJob'))
        $jobs.push(Job.new('HelloMeJob', ['leti', 'esperon']))
      end

      it 'prints the results of the jobs' do
        expected_outputs = []
        expected_outputs << 'Finished computing job HelloWorldJob - Result: Hello World'
        expected_outputs << 'Finished computing job HelloMeJob - Result: Hello World leti esperon'

        expected_outputs.map do |output|
          expect(STDOUT).to receive(:puts).with(output)
        end

       subject.start
      end
    end

    context 'when there are invalid jobs' do
      before do
        $jobs = Queue.new
        $jobs.push(Job.new('InvalidJob'))
        $jobs.push(Job.new('HelloMeJob'))
        $jobs.push(Job.new('HelloWorldJob', ['invalid', 'arguments']))
      end

      it 'prints an error for each invalid job' do
        expected_outputs = []
        expected_outputs << 'Error executing job InvalidJob - Result: That job class is not defined!'
        expected_outputs << 'Error executing job HelloMeJob - Result: The job arguments are not correct :('
        expected_outputs << 'Error executing job HelloWorldJob - Result: The job arguments are not correct :('

        expected_outputs.map do |output|
          expect(STDOUT).to receive(:puts).with(output)
        end

        subject.start
      end
    end
  end
end
