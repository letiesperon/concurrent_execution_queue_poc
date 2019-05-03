require './job.rb'
require './hello_world_job.rb'
require './hello_me_job.rb'

describe Job do
  describe '.initialize' do
    subject(:job) { described_class.new('some_class_name', ['some_param']) }

    it 'assigns an id' do
      expect(subject.id).to be
    end
  end

  describe '#perform' do
    subject(:job) { described_class.new(class_name, params) }

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
        let(:class_name) { 'HelloWorldJob' }

        context 'with no params' do
          let(:params) { nil }

          it 'returns the evaluation of the method on the class' do
            expect_any_instance_of(HelloWorldJob).to receive(:perform).and_return('test')

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
        let(:class_name) { 'HelloMeJob' }

        context 'with valid params' do
          let(:params) { ['leti', 'esperon'] }

          it 'returns the evaluation of the method on the class' do
            expect_any_instance_of(HelloMeJob).to receive(:perform)
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
