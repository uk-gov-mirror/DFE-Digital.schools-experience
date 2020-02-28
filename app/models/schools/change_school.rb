module Schools
  class ChangeSchool
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_reader :current_user, :uuids_to_urns

    attribute :urn, :integer
    validates :urn, presence: true
    validates :urn, inclusion: { in: :organisation_urns }, if: -> { urn.present? }

    class << self
      def allow_school_change_in_app?
        [
          Rails.configuration.x.dfe_sign_in_api_enabled,
          Rails.configuration.x.dfe_sign_in_api_school_change_enabled
        ].all?
      end

      def request_approval_url
        Rails.configuration.x.dfe_sign_in_request_organisation_url
      end
    end

    def initialize(current_user, uuids_to_urns, attributes = {})
      @current_user   = current_user
      @uuids_to_urns  = uuids_to_urns

      super attributes
    end

    def retrieve_valid_school!
      validate!

      if user_has_role_at_school?
        Bookings::School.find_by!(urn: urn)
      else
        raise InaccessibleSchoolError
      end
    end

    def available_schools
      Bookings::School.ordered_by_name.where(urn: organisation_urns)
    end

    def school_uuid
      urns_to_uuids[urn]
    end

    def user_uuid
      current_user.sub
    end

    def task_count_for_urn(urn)
      return nil if organisation_urns.empty?

      school_task_counts[urn]
    end

    class InaccessibleSchoolError < StandardError; end

  private

    def organisation_urns
      uuids_to_urns.values
    end

    def user_has_role_at_school?
      role_checker.has_school_experience_role?
    rescue Faraday::ResourceNotFound, Schools::DFESignInAPI::Roles::NoOrganisationError
      # if the role isn't found the API returns a 404 - this means that the user
      # has insufficient privileges but this *isn't* really an error, so log it
      # and return false
      Rails.logger.warn("Role query yielded 404, user_uuid: #{user_uuid}, school_uuid: #{school_uuid}")

      false
    end

    def role_checker
      Schools::DFESignInAPI::Roles.new user_uuid, school_uuid
    end

    def urns_to_uuids
      uuids_to_urns.invert
    end

    def school_task_counts
      @school_task_counts ||= Bookings::PlacementRequest \
        .joins(:school)
        .where(bookings_schools: { urn: organisation_urns })
        .requiring_attention_including_attendance
        .group('bookings_schools.urn')
        .count(:id)
    end
  end
end
