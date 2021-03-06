# frozen_string_literal: true

module SolidusEasypost
  module Spree
    module ShipmentDecorator
      def self.prepended(base)
        base.state_machine.before_transition(
          to: :shipped,
          do: :buy_easypost_rate,
          if: -> { SolidusEasypost.configuration.purchase_labels }
        )

        base.delegate(
          :easy_post_rate_id,
          :easy_post_shipment_id,
          to: :selected_shipping_rate,
          prefix: :selected,
          allow_nil: true,
        )
      end

      def easypost_shipment
        return unless selected_easy_post_shipment_id

        @easypost_shipment ||= ::EasyPost::Shipment.retrieve(selected_easy_post_shipment_id)
      end

      def easypost_postage_label_url
        easypost_shipment&.postage_label&.label_url
      end

      private

      def buy_easypost_rate
        rate = easypost_shipment.rates.find do |easypost_rate|
          easypost_rate.id == selected_easy_post_rate_id
        end

        easypost_shipment.buy(rate)

        self.tracking = easypost_shipment.tracking_code
      end

      ::Spree::Shipment.prepend self
    end
  end
end
