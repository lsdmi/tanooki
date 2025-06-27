# frozen_string_literal: true

module UserUpdateable
  extend ActiveSupport::Concern

  private

  def user_params
    params.require(:user).permit(:avatar_id, :name)
  end
end
