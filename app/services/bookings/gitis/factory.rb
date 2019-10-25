module Bookings
  module Gitis
    class Factory
      class << self
        def crm; new.crm; end
        alias_method :gitis, :crm
      end

      def crm
        Bookings::Gitis::CRM.new store
      end

      def token
        Bookings::Gitis::Auth.new.token
      end

      def store
        if Rails.application.config.x.gitis.fake_crm
          Bookings::Gitis::Store::Fake.new
        else
          Bookings::Gitis::Store::Dynamics.new token
        end
      end
    end
  end
end
