# frozen_string_literal: true

# Monday (Europe/Kiev) of the week whose 5-of-7 daily-quest streak reward was paid.
class AddWeeklyStreakClaimedOnToTrainerProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :trainer_profiles, :weekly_streak_claimed_on, :date, after: :candies
  end
end
