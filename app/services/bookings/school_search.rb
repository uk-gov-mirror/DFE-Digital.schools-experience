class Bookings::SchoolSearch
  attr_accessor :query, :point, :radius, :subjects, :phases, :max_fee, :order

  # Search for schools based on a query string, location
  # and optional radius. Note, both +.search+ and +.close_to+
  # will not amend the +ActiveRecord::Relation+ if falsy values
  # or empty strings (in the case of +.search+) are passed.
  #
  # This means if one is present and not the other, the query will fall
  # back to the present value. It also means that if none are passed,
  # all schools will be returned.
  def initialize(query, location: nil, radius: 10, subjects: nil, phases: nil, max_fee: nil, requested_order: 'distance')
    self.query    = query
    self.point    = extract_point(location)
    self.radius   = radius
    self.subjects = subjects
    self.phases   = phases
    self.max_fee  = max_fee
    self.order    = order_by(requested_order)
  end

  def results
    Bookings::School
      .search(@query)
      .close_to(@point, radius: @radius)
      .that_provide(@subjects)
      .at_phases(@phases)
      .costing_upto(@max_fee)
      .reorder(@order)
  end

private

  def extract_point(location)
    if (result = Geocoder.search(location)&.first)
      Bookings::School::GEOFACTORY.point(
        result.data.dig('lon'),
        result.data.dig('lat')
      )
    end
  end

  def order_by(requested_order)
    if (requested_order == 'distance') && @point.present?
      # note distance isn't actually an attribute of
      # Bookings::School so we can't use hash syntax
      # as Rails will complain
      'distance asc'
    elsif requested_order == 'fee'
      { fee: 'asc' }
    else # default to alphabetical
      { name: 'asc' }
    end
  end
end
