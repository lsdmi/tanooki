# frozen_string_literal: true

require 'test_helper'

class TrainerProfileTest < ActiveSupport::TestCase
  test 'a new account gets a profile with the starting rating and no clocks' do
    user = User.create!(name: 'New Trainer', email: 'trainer@example.com', password: 'password', avatar: avatars(:one))

    profile = TrainerProfile.find_by!(user:)
    clocks = profile.attributes.values_at('last_catch_at', 'last_training_at', 'last_battle_at')

    assert_equal [Pokemons::Ratings::Glicko2::NEW, [nil] * 3], [profile.glicko, clocks]
  end

  test 'idle periods count fractional days since the last battle' do
    profile = trainer_profiles(:user_one)
    now = Time.zone.parse('2026-10-08 12:00')

    assert_equal 0, profile.idle_periods(now)

    profile.last_battle_at = now - 36.hours

    assert_in_delta 1.5, profile.idle_periods(now)
  end

  test 'an account without a profile gets one on first use' do
    user = users(:user_two)
    trainer_profiles(:user_two).destroy!

    assert_difference('TrainerProfile.count', 1) { user.reload.trainer_profile }
    assert_equal user.trainer_profile, TrainerProfile.find_by(user:)
  end

  test 'training and battle cooldowns run from their clocks' do
    profile = trainer_profiles(:user_one)

    assert_equal [false, false], [profile.training_on_cooldown?, profile.battle_on_cooldown?]

    profile.update!(last_training_at: 1.hour.ago, last_battle_at: 1.hour.ago)

    assert_equal [true, true], [profile.training_on_cooldown?, profile.battle_on_cooldown?]

    profile.update!(last_training_at: 5.hours.ago, last_battle_at: 5.hours.ago)

    assert_equal [false, false], [profile.training_on_cooldown?, profile.battle_on_cooldown?]
  end

  test 'goes away with its user' do
    user = User.create!(name: 'Short Stay', email: 'short@example.com', password: 'password', avatar: avatars(:one))

    assert_difference('TrainerProfile.count', -1) { user.destroy! }
  end
end
