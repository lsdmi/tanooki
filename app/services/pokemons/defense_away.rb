# frozen_string_literal: true

module Pokemons
  # Defense wins/losses since the trainer last opened the Studio Pokémon tab, then stamps the visit.
  class DefenseAway
    Report = Data.define(:wins, :losses) do
      def any? = wins.positive? || losses.positive?
    end
    NONE = Report.new(0, 0)

    def self.claim!(user) = new(user).claim!

    def initialize(user)
      @user = user
      @profile = user.trainer_profile
    end

    def claim!
      report = summarize
      @profile.update!(last_studio_visit_at: Time.current)
      report
    end

    private

    def summarize
      since = @profile.last_studio_visit_at
      return NONE if since.nil?

      defended = PokemonBattle.where(defender_id: @user.id).where(created_at: since..)
      Report.new(defended.where(winner_id: @user.id).count, defended.where.not(winner_id: @user.id).count)
    end
  end
end
