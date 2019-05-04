require './scheduled_worker_server.rb'
require './queue_adapter.rb'
require './scheduled_job.rb'
require 'active_support/time'

describe ScheduledWorkerServer do
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
    let(:now) { Time.current }

    context 'when the jobs are valid' do
      context 'and ready to be ran' do
        let(:jobs) do
          [
            ScheduledJob.new('TestJob', now),
            ScheduledJob.new('TestJobMultipleParams', now, ['leti', 'esperon'])
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
            expect(subject).to receive(:log).with(a_string_including(output))
          end

          subject.start
          subject.stop
        end

        it 'empties the scheduled job queue' do
          expect do
            subject.start
            subject.stop
          end.to change(QueueAdapter.scheduled_jobs, :size).from(2).to(0)
        end
      end

      context 'when the first job is not ready to be ran' do
        before do
          ScheduledJob.new('TestJob', 2.days.from_now).enqueue
          ScheduledJob.new('TestJobMultipleParams', 3.days.from_now, ['leti', 'esperon']).enqueue
        end

        it 'does not perform any job' do
          expect_any_instance_of(ScheduledJob).to_not receive(:perform)

          subject.start
          subject.stop
        end

        it 'does not print anything' do
          expect(subject).to_not receive(:log)

          subject.start
          subject.stop
        end

        it 'does not modify the scheduled job the queue' do
          expect do
            subject.start
            subject.stop
          end.to_not change(QueueAdapter.scheduled_jobs, :size)
        end
      end
    end

    context 'when there are invalid jobs' do
      let(:jobs) do
        [
          ScheduledJob.new('InvalidJob', now),
          ScheduledJob.new('TestJobMultipleParams', now),
          ScheduledJob.new('TestJob', now, ['invalid', 'arguments'])
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
          expect(subject).to receive(:log).with(a_string_including(output))
        end

        subject.start
        subject.stop
      end

      it 'empties the scheduled job queue' do
        expect do
          subject.start
          subject.stop
        end.to change(QueueAdapter.scheduled_jobs, :size).from(3).to(0)
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
