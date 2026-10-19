# frozen_string_literal: true

# Marks the last Pokémon Studio visit so defense wins/losses can show as «Поки вас не було».
class AddLastStudioVisitAtToTrainerProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :trainer_profiles, :last_studio_visit_at, :datetime, after: :last_training_at
  end
end
