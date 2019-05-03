require './hello_world_job.rb'

describe HelloWorldJob do
  describe '#perform' do
    subject { described_class.new.perform }

    it 'returns a greeting' do
      expect(subject).to eq('Hello World')
    end
  end
end
