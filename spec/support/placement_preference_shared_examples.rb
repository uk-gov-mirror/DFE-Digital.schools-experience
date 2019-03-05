shared_examples 'a placement preference' do
  let! :today do
    Date.today
  end

  context 'attributes' do
    it { is_expected.to respond_to :availability }
    it { is_expected.to respond_to :objectives }
  end

  context 'validations' do
    before :each do
      placement_preference.validate
    end

    context 'when availability are not present' do
      let :placement_preference do
        described_class.new
      end

      it 'adds an error to availability' do
        expect(placement_preference.errors[:availability]).to eq \
          ["Enter your availability"]
      end
    end

    context 'when availability are too long' do
      let :placement_preference do
        described_class.new \
          availability: 151.times.map { 'word' }.join(' ')
      end

      it 'adds an error to availability' do
        expect(placement_preference.errors[:availability]).to eq \
          ["Use 150 words or fewer"]
      end
    end

    context 'when objectives are not present' do
      let :placement_preference do
        described_class.new
      end

      it 'adds an error to objectives' do
        expect(placement_preference.errors[:objectives]).to eq \
          ["Enter what you want to get out of a placement"]
      end
    end

    context 'when objectives are too long' do
      let :placement_preference do
        described_class.new \
          objectives: 151.times.map { 'word' }.join(' ')
      end

      it 'adds an error to objectives' do
        expect(placement_preference.errors[:objectives]).to eq \
          ["Use 150 words or fewer"]
      end
    end
  end
end
