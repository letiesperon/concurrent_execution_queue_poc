require './hello_me_job.rb'

describe HelloMeJob do
  describe '#perform' do
    subject { described_class.new.perform('leti', 'esperon') }

    it 'returns a greeting with the full name' do
      expect(subject).to eq('Hello World leti esperon')
    end
  end
end
