# frozen_string_literal: true

module Chapters
  # Restores a chapter from the history list on the composer.
  class RevisionsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_chapter
    before_action :verify_chapter

    def revert
      RevertRevision.call(user: current_user, chapter: @chapter, revision:)
      redirect_to edit_chapter_path(@chapter, page: list_page), notice: t('chapters.notices.revision_restored')
    rescue Api::Error => e
      redirect_to edit_chapter_path(@chapter, page: list_page), alert: refusal(e)
    end

    private

    def set_chapter
      @chapter = Chapter.friendly.find(params.expect(:chapter_id))
    end

    def revision
      @chapter.revisions.find(params.expect(:id))
    end

    def verify_chapter
      return redirect_to root_path unless current_user.manages_chapter?(@chapter)
      return unless @chapter.fiction.license_frozen_for?(current_user)

      redirect_to fiction_path(@chapter.fiction), alert: t('chapters.alerts.licensed')
    end

    def list_page
      page = params[:page].to_i
      page if page > 1
    end

    def refusal(error)
      I18n.t("api.errors.#{error.code}", **error.details.symbolize_keys)
    end
  end
end
