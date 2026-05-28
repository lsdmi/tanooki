# frozen_string_literal: true

# Permitted attributes for updating the signed-in user's profile.
module UserUpdateable
  extend ActiveSupport::Concern

  private

  def user_params
    params.expect(user: %i[avatar_id name])
  end
end
