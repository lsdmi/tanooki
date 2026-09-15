# frozen_string_literal: true

# Guest vs team access for unpublished chapters (drafts and scheduled).
module ChapterPublicAccess
  extend ActiveSupport::Concern

  private

  def redirect_if_chapter_not_yet_public
    return unless @chapter.draft? || @chapter.scheduled?

    if @chapter.draft? && chapter_team_access?
      redirect_to edit_chapter_path(@chapter) unless action_name == 'record_progress'
      return
    end

    return if chapter_team_access?

    redirect_to fiction_path(@chapter.fiction), alert: t('chapters.alerts.not_yet_public')
  end

  def chapter_team_access?
    return true if current_user&.admin?
    return false unless current_user

    current_user.scanlators.ids.intersect?(@chapter.scanlators.ids)
  end
end
