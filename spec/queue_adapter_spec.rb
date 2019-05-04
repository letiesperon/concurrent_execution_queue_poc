require './queue_adapter.rb'
require './scheduled_job.rb'
require './job.rb'
require 'active_support/time'

describe QueueAdapter do
  before do
    QueueAdapter.clear_queues
  end

  after do
    QueueAdapter.clear_queues
  end

  describe '.enqueue' do
    let(:job) { Job.new('Test') }
    subject { QueueAdapter.enqueue(job) }

    it 'adds a new job to the jobs queue' do
      expect {
        subject
      }.to change(described_class.jobs, :size).by(1)
    end
  end

  describe '.enqueue_scheduled' do
    let(:job) { ScheduledJob.new('Test', Time.current) }
    subject { QueueAdapter.enqueue_scheduled(job) }

    it 'adds a new job to the scheduled jobs queue' do
      expect {
        subject
      }.to change(described_class.scheduled_jobs, :size).by(1)
    end

    context 'when there were more jobs queued' do
      let(:job) { ScheduledJob.new('SecondJob', 2.seconds.from_now) }

      before do
        first_job = ScheduledJob.new('FirstJob', 1.second.from_now)
        third_job = ScheduledJob.new('ThirdJob', 50.seconds.from_now)
        QueueAdapter.enqueue_scheduled(third_job)
        QueueAdapter.enqueue_scheduled(first_job)
      end

      it 'enqueues the job in order of performing time' do
        subject

        jobs = QueueAdapter.scheduled_jobs.to_a
        expect(jobs.map(&:class_name)).to eq(['FirstJob', 'SecondJob', 'ThirdJob'])
      end
    end
  end

  describe '.clear_queues' do
    subject { QueueAdapter.clear_queues }

    before do
      job = Job.new('TestJob')
      QueueAdapter.enqueue(job)
      job = ScheduledJob.new('TestJob', 1.second.from_now)
      QueueAdapter.enqueue_scheduled(job)
    end

    it 'empties the jobs queue' do
      expect {
        subject
      }.to change(QueueAdapter.jobs, :size).from(1).to(0)
    end

    it 'empties the scheduled jobs queue' do
      expect {
        subject
      }.to change(QueueAdapter.scheduled_jobs, :size).from(1).to(0)
    end
  end

  describe '.next_job' do
    subject { QueueAdapter.next_job }

    context 'when there are no jobs queued' do
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when there are jobs queued' do
      let(:first_job) { Job.new('FirstJob') }

      before do
        first_job.enqueue
        Job.new('SecondJob').enqueue
      end

      it 'returns the first queued job' do
        expect(subject).to eq(first_job)
      end

      it 'removes the job from the list' do
        expect {
          subject
        }.to change(QueueAdapter.jobs, :size).by(-1)
      end
    end
  end

  describe '.next_scheduled_job' do
    subject { QueueAdapter.next_scheduled_job }

    context 'when there are no jobs queued' do
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when there are jobs queued' do
      before do
        first_job.enqueue
        ScheduledJob.new('SecondJob', 20.seconds.from_now).enqueue
      end

      context 'when the first job is ready to be performed' do
        let(:first_job) { ScheduledJob.new('FirstJob', 10.seconds.ago) }

        it 'returns the first queued job' do
          expect(subject).to eq(first_job)
        end

        it 'removes the job from the list' do
          expect {
            subject
          }.to change(QueueAdapter.scheduled_jobs, :size).by(-1)
        end
      end

      context 'when the first job is not ready to be performed' do
        let(:first_job) { ScheduledJob.new('FirstJob', 10.seconds.from_now) }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end
  end
end
