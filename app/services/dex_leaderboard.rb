# frozen_string_literal: true

class DexLeaderboard
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def call
    dex_list = User.dex_leaders
    user_index = dex_list.index(user)

    if user_index < 10
      dex_list.first(10)
    else
      selected_user_ids = dex_list[user_index - 2..user_index + 2].pluck(:id)
      dex_list.where(id: dex_list.first(3).pluck(:id) + selected_user_ids)
    end
  end
end
