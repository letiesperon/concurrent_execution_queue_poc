require './hello_world_job.rb'
require './hello_me_job.rb'
require './worker_server.rb'

describe WorkerServer do
  subject { described_class.new }

  describe '#start' do
    context 'when the jobs are valid' do
      before do
        $jobs = Queue.new
        $jobs.push(Job.new('HelloWorldJob'))
        $jobs.push(Job.new('HelloMeJob', ['leti', 'esperon']))
      end

      it 'prints the results of the jobs' do
        expected_outprint = []
        expected_outprint << 'Finished computing job HelloWorldJob - Result: Hello World'
        expected_outprint << 'Finished computing job HelloMeJob - Result: Hello World leti esperon'

        expected_outprint.map do |output|
          expect(subject).to receive(:log).with(output).ordered
        end

       subject.start
       subject.stop
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
        first_job_output = 'Error executing job InvalidJob - Result: That job class is not defined!'
        second_job_output = 'Error executing job HelloMeJob - Result: The job arguments are not correct :('
        third_job_output = 'Error executing job HelloWorldJob - Result: The job arguments are not correct :('
        expected_outprint = [first_job_output, second_job_output, third_job_output]

        expected_outprint.map do |output|
          expect(subject).to receive(:log).with(output).ordered
        end

        subject.start
        subject.stop
      end
    end
  end

  describe '#stop' do
    before do
      subject.start
    end

    it 'returns true' do
      expect(subject.stop).to be
    end

    it 'sets stopped in true' do
      subject.stop

      expect(subject.stopped).to be
    end
  end
end
