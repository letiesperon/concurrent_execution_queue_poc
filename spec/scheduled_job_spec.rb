require './scheduled_job.rb'
require 'active_support/time'

describe ScheduledJob do
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

  let(:class_name) { 'some_class_name' }
  let(:params) { ['some_param'] }
  let(:perform_at) { Time.current }
  subject(:scheduled_job) { described_class.new(class_name, perform_at, params) }

  describe '.initialize' do
    it 'assigns an id' do
      expect(subject.id).to be
    end

    it 'assigns the class name' do
      expect(subject.class_name).to eq('some_class_name')
    end

    it 'assigns the params' do
      expect(subject.params).to eq(params)
    end

    it 'assigns the perform_at' do
      expect(subject.perform_at).to eq(perform_at)
    end
  end

  describe '#ready_to_run?' do
    context 'when perform_at is in the future' do
      let(:perform_at) { 10.seconds.from_now }

      it 'is false' do
        expect(subject.ready_to_run?).to eq(false)
      end
    end

    context 'when perform_at is in the past' do
      let(:perform_at) { 10.seconds.ago }

      it 'is true' do
        expect(subject.ready_to_run?).to eq(true)
      end
    end
  end

  describe '#enqueue' do
    it 'delegates enqueing to queue adapter' do
      expect(QueueAdapter).to receive(:enqueue_scheduled).with(subject)

      subject.enqueue
    end
  end

  describe '#perform' do
    context 'when the class does not exist' do
      let(:class_name) { 'Invalid' }
      let(:params) { nil }

      context 'with some params' do
       let(:params) { ['invalid'] }

        it 'returns nil' do
          expect(subject.perform).to be_nil
        end

        it 'assigns an error' do
          subject.perform

          expect(subject.error).to_not be_nil
        end
      end
    end

    context 'when the class exists' do
      context 'when the method in the class does not expect params' do
        let(:class_name) { 'TestJob' }

        context 'with no params' do
          let(:params) { nil }

          it 'returns the evaluation of the method on the class' do
            expect_any_instance_of(TestJob).to receive(:perform).and_return('test')

            expect(subject.perform).to eq('test')
          end

          it 'does not assign an error' do
            subject.perform

            expect(subject.error).to be_nil
          end
        end

        context 'with some params' do
          let(:params) { ['invalid'] }

          it 'returns nil' do
            expect(subject.perform).to be_nil
          end

          it 'assigns an error' do
            subject.perform

            expect(subject.error).to_not be_nil
          end
        end
      end

      context 'when the method in the class expects params' do
        let(:class_name) { 'TestJobMultipleParams' }

        context 'with valid params' do
          let(:params) { ['leti', 'esperon'] }

          it 'returns the evaluation of the method on the class' do
            expect_any_instance_of(TestJobMultipleParams).to receive(:perform)
              .with('leti', 'esperon').and_return('test')

            expect(subject.perform).to eq('test')
          end

          it 'does not assign an error' do
            subject.perform

            expect(subject.error).to be_nil
          end
        end

        context 'with no params' do
          let(:params) { nil }

          it 'returns nil' do
            expect(subject.perform).to be_nil
          end

          it 'assigns an error' do
            subject.perform

            expect(subject.error).to_not be_nil
          end
        end
      end
    end
  end
end
