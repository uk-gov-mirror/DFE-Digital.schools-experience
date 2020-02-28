require 'rails_helper'

describe Schools::ChangeSchool, type: :model do
  let(:first_school) { create(:bookings_school) }
  let(:second_school) { create(:bookings_school) }
  let(:user_uuid) { SecureRandom.uuid }
  let(:user) { Struct.new(:sub).new(user_uuid) }
  let(:current_urn) { nil }
  let(:user_has_role) { true }
  let(:uuid_map) do
    {
      SecureRandom.uuid => first_school.urn,
      SecureRandom.uuid => second_school.urn,
      SecureRandom.uuid => 1000000
    }
  end
  let(:change_school) { described_class.new(user, uuid_map, urn: current_urn) }

  before do
    allow(Schools::DFESignInAPI::Roles).to \
      receive(:new).and_call_original

    allow_any_instance_of(Schools::DFESignInAPI::Roles).to \
      receive(:has_school_experience_role?) { user_has_role }
  end

  subject { change_school }

  describe 'attributes' do
    it { is_expected.to respond_to :urn }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :urn }
    it { is_expected.to validate_inclusion_of(:urn).in_array uuid_map.values }
  end

  describe '#available_schools' do
    it 'should only return schools which we have in our system' do
      is_expected.to have_attributes \
        available_schools: match_array([first_school, second_school])
    end
  end

  describe '#school_uuid' do
    let(:current_urn) { second_school.urn }
    it { is_expected.to have_attributes school_uuid: uuid_map.keys[1] }
  end

  describe '#user_uuid' do
    it { is_expected.to have_attributes user_uuid: user_uuid }
  end

  describe '#retrieve_valid_school!' do
    let(:current_urn) { second_school.urn }

    context 'with unknown urn' do
      let(:current_urn) { 20000 }

      it 'will raise exception' do
        expect { subject.retrieve_valid_school! }.to \
          raise_exception(ActiveModel::ValidationError)
      end
    end

    context 'with valid urn and passing role check' do
      before { subject.retrieve_valid_school! }

      it 'should call role api' do
        expect(Schools::DFESignInAPI::Roles).to \
          have_received(:new).with(user_uuid, uuid_map.keys[1])
      end
    end

    context 'wth valid urn and failing role check' do
      let(:user_has_role) { false }

      it 'should call role api and raise exception' do
        expect { subject.retrieve_valid_school! }.to \
          raise_exception(Schools::ChangeSchool::InaccessibleSchoolError)

        expect(Schools::DFESignInAPI::Roles).to \
          have_received(:new).with(user_uuid, uuid_map.keys[1])
      end
    end
  end

  describe '#task_count_for_urn' do
    context 'with unexpected URN' do
      subject { change_school.task_count_for_urn 987654 }
      it { is_expected.to be_nil }
    end

    context 'with known URN' do
      before do
        create :placement_request, school: first_school
        create :placement_request, school: second_school

        create :placement_request, :booked, school: first_school do |pr|
          pr.booking.update_columns date: Date.yesterday
        end
      end

      subject { change_school.task_count_for_urn first_school.urn }

      it "should include count only for requested school" do
        is_expected.to eql 2
      end
    end
  end
end
