require 'rails_helper'
require Rails.root.join("spec", "controllers", "schools", "session_context")

describe Schools::PreviousBookingsController, type: :request do
  include_context "logged in DfE user"
  include_context "fake gitis"

  let! :school do
    Bookings::School.find_by!(urn: urn).tap do |s|
      s.subjects << FactoryBot.create_list(:bookings_subject, 2)
      create(:bookings_profile, school: s)
    end
  end

  describe '#index' do
    before { get schools_previous_bookings_path }
    it { expect(response).to have_http_status(:success) }
    it { expect(response).to render_template('index') }
  end
end
