# frozen_string_literal: true

class LibraryController < ApplicationController
  before_action :authenticate_user!

  def index
    @history = current_user.readings.includes(
      [{ fiction: { cover_attachment: :blob } }, { fiction: :genres }, :chapter]
    ).order(updated_at: :desc)
  end
end
