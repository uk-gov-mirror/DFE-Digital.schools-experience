class Bookings::SchoolSearch < ApplicationRecord
  attr_accessor :requested_order
  attr_reader :location_name

  validates :location, length: { minimum: 3 }, allow_nil: true

  AVAILABLE_ORDERS = [
    %w[distance Distance],
    %w[name Name]
  ].freeze

  REGION = 'England'.freeze
  GEOCODER_PARAMS = { maxRes: 1 }.freeze
  PER_PAGE = 15

  class << self
    def available_orders
      AVAILABLE_ORDERS.map
    end

    def whitelisted_urns
      return [] if ENV['CANDIDATE_URN_WHITELIST'].blank?

      ENV['CANDIDATE_URN_WHITELIST'].to_s.strip.split(%r{[\s,]+}).map(&:to_i)
    end

    def whitelisted_urns?
      whitelisted_urns.any?
    end
  end
  delegate :whitelisted_urns, :whitelisted_urns?, to: :class

  def initialize(attributes = {})
    # location can be passed in as a hash or a string, we don't want to write a
    # hash to a string field so wipe it if necessary.
    @location_attribute = attributes[:location]
    attributes[:location] = nil if @location_attribute.is_a?(Hash)

    super

    self.coordinates = parse_location(@location_attribute)
  end

  def results
    base_query
      .includes(%i[phases])
      .reorder(order_by(requested_order))
      .page(page)
      .per(PER_PAGE)
  end

  def total_count
    base_query(include_distance: false).count.tap do |count|
      save_with_result_count(count)
    end
  end

  class InvalidCoordinatesError < ArgumentError
    def initialize(msg = "Invalid coordinates - :latitude or :longitude keys are missing", *args)
      super(msg, *args)
    end
  end

  class InvalidGeocoderResultError < ArgumentError
    def initialize(msg = "Invalid geocoder result - :latitude or :longitude keys are missing", *args)
      super(msg, *args)
    end
  end

  def has_coordinates?
    coordinates.present?
  end

  def radius=(dist)
    self[:radius] = if whitelisted_urns?
                      1000 # include all whitelisted schools but still order by distance
                    else
                      dist
                    end
  end

private

  def save_with_result_count(count)
    self.number_of_results = count
    save
  end

  # Note, all of the scopes provided by +Bookings::School+ will not
  # amend the +ActiveRecord::Relation+ if no param is provided, meaning
  # they can be safely chained
  def base_query(include_distance: true)
    whitelisted_base_query
      .close_to(coordinates, radius: radius, include_distance: include_distance)
      .that_provide(subjects)
      .at_phases(phases)
      .costing_upto(max_fee)
      .enabled
      .with_availability
      .distinct
      .includes([:available_placement_dates])
  end

  def whitelisted_base_query
    if whitelisted_urns?
      Bookings::School.where(urn: whitelisted_urns)
    else
      Bookings::School
    end
  end

  def parse_location(location)
    if location.is_a?(Hash)
      extract_coords(location) || raise(InvalidCoordinatesError)
    elsif location.present?
      geolocate(location)
    end
  end

  def extract_coords(coords)
    coords = coords.symbolize_keys

    if coords.key?(:latitude) && coords.key?(:longitude)
      Bookings::School::GEOFACTORY.point(
        coords[:longitude],
        coords[:latitude]
      )
    elsif coords.key?(:lat)
      if coords.key?(:lng)
        Bookings::School::GEOFACTORY.point(coords[:lng], coords[:lat])
      elsif coords.key?(:lon)
        Bookings::School::GEOFACTORY.point(coords[:lon], coords[:lat])
      end
    end
  end

  def geolocate(location)
    result = Geocoder.search(
      [location, REGION].join(", "),
      params: GEOCODER_PARAMS
    )&.first

    if empty_geocoder_result?(result)
      Rails.logger.info("No Geocoder results found in #{REGION} for #{location}")
      return
    end

    raise InvalidGeocoderResultError unless valid_geocoder_result?(result)

    # this better work
    @location_name = result.try(:name) || result.address_components.first.fetch('long_name', location)
    extract_coords(
      latitude: result.latitude,
      longitude: result.longitude
    )
  end

  def empty_geocoder_result?(result)
    result.blank? || result.try(:name) == REGION
  end

  def valid_geocoder_result?(result)
    result.is_a?(Geocoder::Result::Base) &&
      result.longitude.present? &&
      result.latitude.present?
  end

  def order_by(option)
    if (option == 'distance') && coordinates.present?
      # note distance isn't actually an attribute of
      # Bookings::School so we can't use hash syntax
      # as Rails will complain
      'distance asc'
    else
      { name: 'asc' }
    end
  end
end
