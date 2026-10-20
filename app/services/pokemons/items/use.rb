# frozen_string_literal: true

module Pokemons
  module Items
    # Spends one bag item and applies its effect. Returns a notice string, or nil when the item cannot be used.
    class Use
      def self.call(user, item_key:, user_pokemon_id: nil, habitat: nil)
        new(user).call(item_key:, user_pokemon_id:, habitat:)
      end

      def initialize(user)
        @user = user
        @profile = user.trainer_profile
      end

      def call(item_key:, user_pokemon_id: nil, habitat: nil)
        key = item_key.to_s
        return unless Catalog.known?(key)

        @profile.with_lock do
          row = TrainerItem.find_by(user_id: @user.id, item_key: key)
          return if row.nil? || row.quantity < 1

          notice = apply!(key, user_pokemon_id:, habitat:)
          return unless notice

          row.update!(quantity: row.quantity - 1)
          notice
        end
      end

      private

      def apply!(key, user_pokemon_id:, habitat:)
        definition = Catalog.fetch(key)
        effect = definition.fetch('effect')
        return level_up!(user_pokemon_id) if effect == 'level_up'
        return set_lure!(habitat) if effect == 'lure'
        return apply_cosmetic!(definition) if effect == 'cosmetic'

        apply_simple!(effect)
      end

      def apply_cosmetic!(definition)
        flag = definition.fetch('flag')
        set_flag!(flag, true, "pokemons.items.used.#{flag}")
      end

      def apply_simple!(effect)
        return clear_cooldown!(:training) if effect == 'clear_training_cooldown'
        return clear_cooldown!(:battle) if effect == 'clear_battle_cooldown'

        flag_effects = {
          'incense' => 'incense', 'lucky_egg' => 'lucky_egg',
          'reroll_ticket' => 'reroll_ticket', 'x_attack' => 'x_attack'
        }
        flag = flag_effects[effect]
        set_flag!(flag, true, "pokemons.items.used.#{flag}") if flag
      end

      def clear_cooldown!(kind)
        if kind == :training
          @profile.update!(last_training_at: nil)
          I18n.t('pokemons.items.used.training_tonic')
        else
          @profile.update!(last_battle_at: nil)
          I18n.t('pokemons.items.used.battle_tonic')
        end
      end

      def level_up!(user_pokemon_id)
        record = @user.user_pokemons.find_by(id: user_pokemon_id)
        return if record.nil?

        name = record.pokemon_name
        record.level_up!
        I18n.t('pokemons.items.used.protein', name:)
      end

      def set_lure!(habitat)
        type = habitat.to_s.downcase.presence
        return if type.blank?
        return unless Habitat.known_type_keys.include?(type)

        @profile.write_item_effect!('lure', type)
        I18n.t('pokemons.items.used.lure', type: I18n.t("pokemons.types.#{type}"))
      end

      def set_flag!(key, value, i18n_key)
        @profile.write_item_effect!(key, value)
        I18n.t(i18n_key)
      end
    end
  end
end
