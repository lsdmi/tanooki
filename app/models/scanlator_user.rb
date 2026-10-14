# frozen_string_literal: true

# Join model linking users to scanlator teams.
class ScanlatorUser < ApplicationRecord
  belongs_to :scanlator, counter_cache: :members_count
  belongs_to :user

  after_destroy_commit :revoke_access_without_a_team

  private

  def revoke_access_without_a_team
    return if user.scanlator_users.exists?

    Api::RevokeAccess.call(user)
  end
end
