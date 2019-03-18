require 'rails_helper'

describe Bookings::SchoolSearch do
  let(:manchester_coordinates) {
    [
      Geocoder::Result::Test.new("latitude" => 53.488, "longitude" => -2.242),
      Geocoder::Result::Test.new("latitude" => 53.476, "longitude" => -2.229)
    ]
  }

  describe '#geolocation' do
    let(:location) { 'Springfield' }

    context 'when Geocoder returns invalid results' do
      let(:expected_error) { Bookings::SchoolSearch::InvalidGeocoderResultError }
      before do
        allow(Geocoder).to receive(:search).and_return('something bad')
      end

      specify 'an error should be raised' do
        expect { Bookings::SchoolSearch.new('', location: 'France') }.to raise_error(expected_error)
      end
    end
  end

  describe '#results' do
    context 'Search Criteria' do
      before do
        allow(Geocoder).to receive(:search).and_return([])
      end

      let(:point_in_manchester) { Bookings::School::GEOFACTORY.point(-2.241, 53.481) }
      let(:point_in_leeds) { Bookings::School::GEOFACTORY.point(-1.548, 53.794) }

      let!(:matching_school) do
        create(
          :bookings_school,
          name: "Springfield Primary School",
          coordinates: point_in_manchester,
          fee: 10
        )
      end

      let!(:non_matching_school) do
        create(
          :bookings_school,
          name: "Pontefract Primary School",
          coordinates: point_in_leeds,
          fee: 30
        )
      end

      context 'When no conditions are supplied' do
        subject { Bookings::SchoolSearch.new('', location: '').results }
        specify 'results should include all schools' do
          expect(subject.count).to eql(Bookings::School.count)
        end
      end

      context 'When coodinates are supplied' do
        let!(:coords) { manchester_coordinates[0] }

        context 'When text and latitude and longitude are supplied' do
          subject do
            Bookings::SchoolSearch.new('Springfield', location: {
              latitude: coords.latitude, longitude: coords.longitude
            }).results
          end

          specify 'results should include matching records' do
            expect(subject).to include(matching_school)
          end

          specify 'results should not include non-matching records' do
            expect(subject).not_to include(non_matching_school)
          end
        end

        context 'When only lat and lon are supplied' do
          subject do
            Bookings::SchoolSearch.new(
              '',
              location: { latitude: coords.latitude, longitude: coords.longitude }
            ).results
          end

          let!(:matching_school) do
            create(:bookings_school, name: "Springfield Primary School")
          end

          specify 'results should include matching records' do
            expect(subject).to include(matching_school)
          end

          specify 'results should not include non-matching records' do
            expect(subject).not_to include(non_matching_school)
          end
        end

        context 'When only latitude is supplied' do
          subject do
            Bookings::SchoolSearch.new('', location: {
              latitude: coords.latitude
            })
          end

          it("should raise error") do
            expect {
              subject.results
            }.to raise_exception(Bookings::SchoolSearch::InvalidCoordinatesError)
          end
        end

        context 'When only longitude is supplied' do
          subject do
            Bookings::SchoolSearch.new('', location: {
              longitude: coords.longitude
            })
          end

          it("should raise error") do
            expect {
              subject.results
            }.to raise_exception(Bookings::SchoolSearch::InvalidCoordinatesError)
          end
        end
      end

      context 'Geocoder' do
        context 'When Geocoder finds a location' do
          before do
            allow(Geocoder).to receive(:search).and_return(manchester_coordinates)
          end

          context 'When text and location are supplied' do
            subject { Bookings::SchoolSearch.new('Springfield', location: 'Manchester').results }

            specify 'results should include matching records' do
              expect(subject).to include(matching_school)
            end

            specify 'results should not include non-matching records' do
              expect(subject).not_to include(non_matching_school)
            end
          end

          context 'When only text is supplied' do
            subject { Bookings::SchoolSearch.new('Springfield').results }

            let!(:matching_school) do
              create(:bookings_school, name: "Springfield Primary School")
            end

            specify 'results should include matching records' do
              expect(subject).to include(matching_school)
            end

            specify 'results should not include non-matching records' do
              expect(subject).not_to include(non_matching_school)
            end
          end

          context 'When only a location is supplied' do
            subject { Bookings::SchoolSearch.new('', location: 'Manchester').results }

            let!(:matching_school) do
              create(:bookings_school, name: "Springfield Primary School")
            end

            specify 'results should include matching records' do
              expect(subject).to include(matching_school)
            end

            specify 'results should not include non-matching records' do
              expect(subject).not_to include(non_matching_school)
            end
          end
        end

        context 'When Geocoder finds no location' do
          context 'When the query matches a school' do
            before do
              allow(Geocoder).to receive(:search).and_return([])
            end

            subject { Bookings::SchoolSearch.new('Springfield', location: 'Madrid').results }

            specify 'results should include records that match the query' do
              expect(subject).to include(matching_school)
            end
          end

          context 'When the query does not match a school' do
            subject { Bookings::SchoolSearch.new('William McKinley High', location: 'Chippewa, Michigan').results }

            specify 'results should include records that match the query' do
              expect(subject).to be_empty
            end
          end
        end

        context 'When Geocoder returns an invalid location' do
          context 'When the query matches a school' do
            before do
              allow(Geocoder).to receive(:search).and_return("ABC123")
            end

            subject { Bookings::SchoolSearch.new('', location: 'Madrid') }

            specify 'should fail with a InvalidGeocoderResultError' do
              expect { subject.results }.to raise_error(Bookings::SchoolSearch::InvalidGeocoderResultError)
            end
          end
        end
      end

      context 'Filtering' do
        # subjects
        let(:maths) { create(:bookings_subject, name: "Maths") }
        let(:physics) { create(:bookings_subject, name: "Physics") }
        # phases
        let(:college) { create(:bookings_phase, name: "College") }
        let(:secondary) { create(:bookings_phase, name: "Secondary") }

        context 'Filtering on subjects' do
          before do
            matching_school.subjects << maths
            non_matching_school.subjects << physics
          end

          subject { Bookings::SchoolSearch.new('', location: '', subjects: maths).results }

          specify 'should return matching results' do
            expect(subject).to include(matching_school)
          end

          specify 'should omit non-matching results' do
            expect(subject).not_to include(non_matching_school)
          end
        end

        context 'Filtering on phases' do
          before do
            matching_school.phases << college
            non_matching_school.phases << secondary
          end

          subject { Bookings::SchoolSearch.new('', location: '', phases: college).results }

          specify 'should return matching results' do
            expect(subject).to include(matching_school)
          end

          specify 'should omit non-matching results' do
            expect(subject).not_to include(non_matching_school)
          end
        end

        context 'Filtering on fees' do
          subject { Bookings::SchoolSearch.new('', location: '', max_fee: 20).results }

          specify 'should return matching results' do
            expect(subject).to include(matching_school)
          end

          specify 'should omit non-matching results' do
            expect(subject).not_to include(non_matching_school)
          end
        end
      end

      context 'Chaining' do
        let(:secondary) { create(:bookings_phase, name: "Secondary") }
        let(:physics) { create(:bookings_subject, name: "Physics") }

        before do
          allow(Geocoder).to receive(:search).and_return(manchester_coordinates)
        end

        before do
          matching_school.phases << secondary
          matching_school.subjects << physics
        end

        subject do
          Bookings::SchoolSearch.new(
            'Springf',
            location: 'Cheetham Hill',
            subjects: physics,
            phases: secondary,
            max_fee: 20
          ).results
        end

        specify 'should allow all search options and filters to work in conjunction' do
          expect(subject).to include(matching_school)
        end
      end
    end

    context 'Ordering' do
      context 'Geographic ordering' do
        let(:point_in_manchester) { Bookings::School::GEOFACTORY.point(-2.241, 53.481) }
        let(:point_in_leeds) { Bookings::School::GEOFACTORY.point(-1.548, 53.794) }
        let(:point_in_glasgow) { Bookings::School::GEOFACTORY.point(-4.219, 55.859) }
        let(:point_in_york) { Bookings::School::GEOFACTORY.point(-1.095, 53.597) }

        let!(:glasgow_school) { create(:bookings_school, name: "Glasgow", coordinates: point_in_glasgow) }
        let!(:york_school) { create(:bookings_school, name: "York", coordinates: point_in_york) }
        let!(:mcr_school) { create(:bookings_school, name: "Manchester", coordinates: point_in_manchester) }
        let!(:leeds_school) { create(:bookings_school, name: "Leeds", coordinates: point_in_leeds) }

        before do
          allow(Geocoder).to receive(:search).and_return(manchester_coordinates)
        end

        subject do
          Bookings::SchoolSearch.new('', location: 'Cheetham Hill', radius: 500, requested_order: 'distance').results
        end

        specify 'schools should be ordered by distance, near to far' do
          expect(subject.map(&:name)).to eql([mcr_school, leeds_school, york_school, glasgow_school].map(&:name))
        end
      end

      context 'Sorting by name' do
        let!(:cardiff) { create(:bookings_school, name: "Cardiff Comprehensive") }
        let!(:bath) { create(:bookings_school, name: "Bath High School") }
        let!(:coventry) { create(:bookings_school, name: "Coventry Academy") }

        subject do
          Bookings::SchoolSearch.new('', requested_order: 'name').results
        end

        specify 'schools should be ordered alphabetically by name' do
          expect(subject.map(&:name)).to eql([bath, cardiff, coventry].map(&:name))
        end
      end
    end
  end

  describe '#total_count' do
    let!(:matching_schools) do
      create_list(:bookings_school, 8)
    end

    let!(:non_matching_school) do
      create(:bookings_school, name: "Non-matching establishment")
    end

    specify 'total count should match the number of matching schools' do
      expect(Bookings::SchoolSearch.new("school").total_count).to eql(matching_schools.length)
    end
  end
end
