# frozen_string_literal: true

module Pokemons
  module Candies
    # Awards candies under an already-locked trainer profile (or locks if +profile+ is omitted).
    class Grant
      def self.call(user, amount:, reason:, source: nil, profile: nil)
        new(user, profile:).call(amount:, reason:, source:)
      end

      def initialize(user, profile: nil)
        @user = user
        @profile = profile
      end

      def call(amount:, reason:, source: nil)
        return if amount.to_i.zero?

        if @profile
          apply!(amount.to_i, reason, source)
        else
          @user.trainer_profile.with_lock do
            @profile = @user.trainer_profile
            apply!(amount.to_i, reason, source)
          end
        end
      end

      private

      def apply!(amount, reason, source)
        @profile.update!(candies: @profile.candies + amount)
        CandyTransaction.create!(
          user: @user, amount:, reason: reason.to_s, source:
        )
      end
    end
  end
end
