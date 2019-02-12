require 'rails_helper'

describe Notify do
  let(:to) { 'somename@somecompany.org' }
  subject { Notify.new(to: to) }

  describe 'Attributes' do
    it { is_expected.to respond_to(:to) }
    it { is_expected.to respond_to(:notify_client) }
  end

  describe 'Initialization' do
    specify 'should assign email address' do
      expect(subject.to).to eql(to)
    end

    specify 'should set up a notify client with the correct API key' do
      expect(subject.notify_client).to be_a(Notifications::Client)
    end
  end

  describe 'Methods' do
    describe '#despatch!' do
      it "should fail with 'Not implemented'" do
        expect { subject.despatch! }.to raise_error('Not implemented')
      end
    end

    context 'Private methods' do
      describe '#personalisation' do
        it "should fail with 'Not implemented'" do
          expect { subject.send(:personalisation) }.to raise_error('Not implemented')
        end
      end

      describe '#template_id' do
        it "should fail with 'Not implemented'" do
          expect { subject.send(:template_id) }.to raise_error('Not implemented')
        end
      end
    end
  end
end
