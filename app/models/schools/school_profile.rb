module Schools
  class SchoolProfile < ApplicationRecord
    validates :urn, presence: true, uniqueness: true

    composed_of \
      :candidate_requirement,
      class_name: 'Schools::OnBoarding::CandidateRequirement',
      mapping: [
        %w(candidate_requirement_dbs_requirement dbs_requirement),
        %w(candidate_requirement_dbs_policy dbs_policy),
        %w(candidate_requirement_requirements requirements),
        %w(candidate_requirement_requirements_details requirements_details)
      ],
      constructor: :compose

    composed_of \
      :fees,
      class_name: 'Schools::OnBoarding::Fees',
      mapping: [
        %w(fees_administration_fees administration_fees),
        %w(fees_dbs_fees dbs_fees),
        %w(fees_other_fees other_fees)
      ],
      constructor: :compose

    composed_of \
      :administration_fee,
      class_name: 'Schools::OnBoarding::AdministrationFee',
      mapping: []

    composed_of \
      :dbs_fee,
      class_name: 'Schools::OnBoarding::DBSFee',
      mapping: []

    composed_of \
      :other_fee,
      class_name: 'Schools::OnBoarding::OtherFee',
      mapping: []
  end
end
