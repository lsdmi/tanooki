# frozen_string_literal: true

# Ordered attack / defense battle rosters (arrays of user_pokemon ids) on each trainer.
class AddTeamRostersToTrainerProfiles < ActiveRecord::Migration[8.1]
  def change
    change_table :trainer_profiles, bulk: true do |t|
      t.json :attack_team_ids, after: :pinned_until
      t.json :defense_team_ids, after: :attack_team_ids
    end
  end
end
