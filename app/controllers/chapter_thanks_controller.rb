# frozen_string_literal: true

# Reader thanks on a chapter: the first tap thanks it, the next takes the thanks back. JSON for the reader bar.
class ChapterThanksController < ApplicationController
  ERROR_STATUSES = { own_work: :forbidden, not_released: :unprocessable_content }.freeze

  before_action :authenticate_user!
  rate_limit to: 30, within: 1.minute, by: -> { current_user.id }, only: :create

  def create
    chapter = Chapter.friendly.find(params.expect(:chapter_id))
    result = Chapters::ToggleThank.call(chapter:, user: current_user)
    return render_error(result.error) unless result.ok

    render json: { thanked: result.thanked, thanks_count: result.thanks_count,
                   thanks_count_label: t('chapters.thanks.count', count: result.thanks_count) }
  end

  private

  def render_error(error)
    render json: { error: t("chapters.thanks.errors.#{error}") }, status: ERROR_STATUSES.fetch(error)
  end
end
