require 'rails_helper'
require File.join(Rails.root, 'spec', 'support', 'notify_fake_client')
require File.join(Rails.root, 'spec', 'support', 'notify_retryable_erroring_client')

describe Notify do
  include ActiveJob::TestHelper
  let(:to) { 'somename@somecompany.org' }

  before do
    allow(NotifyService.instance).to receive(:send_email)
  end

  subject { Notify.new(to: to) }

  describe 'Attributes' do
    it { is_expected.to respond_to(:to) }
  end

  describe 'Initialization' do
    specify 'should assign an array of email address' do
      expect(subject.to).to match_array(to)
    end

    context 'with duplicates' do
      let(:to) { ['somename@somecompany.org', 'somename@somecompany.org'] }

      specify 'should remove duplicates' do
        expect(subject.to).to match_array(to.uniq)
      end
    end
  end

  describe 'Methods' do
    describe '#despatch_later!' do
      it "should fail with 'Not implemented'" do
        expect { subject.despatch_later! }.to raise_error('Not implemented')
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

  describe 'custom notify_client' do
    class StubNotification < Notify
      attr_accessor :name

      def initialize(to:, name:)
        self.name = name
        super(to: to)
      end

    private

      def template_id
        'ec830a0d-d032-4d4b-a107-xxxxyyyyzzzz'
      end

      def personalisation
        { name: name }
      end
    end

    let :notification do
      StubNotification.new to: recipients, name: 'Test User'
    end

    let :recipients do
      %w(test1@user.com test2@user.com)
    end

    describe '#despatch_later!' do
      before do
        perform_enqueued_jobs do
          notification.despatch_later!
        end
      end

      it "should enqueue a notify job with the correct parameters" do
        recipients.each do |recipient|
          expect(NotifyService.instance).to have_received(:send_email).with \
            email_address: recipient,
            template_id: notification.send(:template_id),
            personalisation: notification.send(:personalisation)
        end
      end
    end
  end
end
