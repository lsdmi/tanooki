# frozen_string_literal: true

module Pokemons
  # Deletes the Action Text bodies of pokemon_battle_logs (about 13 KB each) in small batches with a pause between them,
  # so no single statement holds hundreds of MB in the binlog. Orphans whose log is already gone go too: rows are found
  # by record_type alone. Refuses to start while a log has no legacy PokemonBattle row, e.g. a battle the old code
  # logged during the deploy that converted them; rerun the conversion first.
  class LegacyBattleLogPurge
    RECORD_TYPE = 'PokemonBattleLog'
    class Unconverted < StandardError; end

    def initialize(batch_size: 500, pause: 1)
      @batch_size = batch_size
      @pause = pause
    end

    def remaining
      bodies.count
    end

    def unconverted
      PokemonBattleLog.count - PokemonBattle.legacy.count
    end

    # Yields the running total after each batch; returns it.
    def call
      raise Unconverted, "#{unconverted} battle logs have no legacy pokemon_battles row" if unconverted.positive?

      deleted = 0
      while (ids = bodies.limit(@batch_size).pluck(:id)).any?
        deleted += ActionText::RichText.where(id: ids).delete_all
        yield deleted if block_given?
        sleep @pause
      end
      deleted
    end

    private

    def bodies
      ActionText::RichText.where(record_type: RECORD_TYPE)
    end
  end
end
