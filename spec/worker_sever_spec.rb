require './worker_server.rb'
require './queue_adapter.rb'
require './job.rb'

describe WorkerServer do
  class TestJob
    def perform
      'result'
    end
  end

  class TestJobMultipleParams
    def perform(_first_param, _second_param)
      'result'
    end
  end

  subject { described_class.new }

  before do
    QueueAdapter.clear_queues
    allow_any_instance_of(Object).to receive(:sleep)
    allow(subject).to receive(:log)
  end

  describe '#start' do
    context 'when the jobs are valid' do
      let(:jobs) do
        [
          Job.new('TestJob'),
          Job.new('TestJobMultipleParams', ['leti', 'esperon'])
        ]
      end

      before do
        jobs.map(&:enqueue)
      end

      it 'performs the jobs' do
        jobs.each do |job|
          expect(job).to receive(:perform).and_call_original
        end

        subject.start
        subject.stop
      end

      it 'prints the results of the jobs' do
        expected_outprint = []
        expected_outprint << 'TestJob - Result: result'
        expected_outprint << 'TestJobMultipleParams - Result: result'

        expected_outprint.map do |output|
          expect(subject).to receive(:log).with(a_string_including(output)).ordered
        end

        subject.start
        subject.stop
      end

      it 'empties the job queue' do
        expect do
          subject.start
          subject.stop
        end.to change(QueueAdapter.jobs, :size).from(2).to(0)
      end
    end

    context 'when there are invalid jobs' do
      let(:jobs) do
        [
          Job.new('InvalidJob'),
          Job.new('TestJobMultipleParams'),
          Job.new('TestJob', ['invalid', 'arguments'])
        ]
      end

      before do
        jobs.map(&:enqueue)
      end

      it 'performs the jobs' do
        jobs.each do |job|
          expect(job).to receive(:perform).and_call_original
        end

        subject.start
        subject.stop
      end

      it 'prints an error for each invalid job' do
        first_job_output = 'That job class is not defined!'
        second_job_output = 'The job arguments are not correct :('
        third_job_output = 'The job arguments are not correct :('
        expected_outprint = [first_job_output, second_job_output, third_job_output]

        expected_outprint.map do |output|
          expect(subject).to receive(:log).with(a_string_including(output)).ordered
        end

        subject.start
        subject.stop
      end

      it 'empties the job queue' do
        expect do
          subject.start
          subject.stop
        end.to change(QueueAdapter.jobs, :size).from(3).to(0)
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
