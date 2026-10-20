# frozen_string_literal: true

module Pokemons
  module Items
    # Adds +quantity+ of an item to the bag (caller should hold the profile lock when awarding quest loot).
    class Grant
      def self.call(user, item_key:, quantity: 1)
        new(user).call(item_key:, quantity:)
      end

      def initialize(user)
        @user = user
      end

      def call(item_key:, quantity: 1)
        key = item_key.to_s
        raise ArgumentError, "unknown item #{key}" unless Catalog.known?(key)
        return if quantity.to_i <= 0

        row = TrainerItem.find_or_initialize_by(user_id: @user.id, item_key: key)
        row.quantity = row.quantity.to_i + quantity.to_i
        row.save!
        row
      end
    end
  end
end
