# frozen_string_literal: true

module Chapters
  # Composer "Вставити Markdown": converts pasted Markdown (a chat answer, say) to chapter HTML for the editor.
  # Nothing is saved here; the translator reviews the result and saves the chapter as usual.
  class MarkdownImportsController < ApplicationController
    MAX_BYTES = 2.megabytes

    before_action :authenticate_user!
    rate_limit to: 60, within: 1.minute, by: -> { current_user.id }, only: :create,
               with: -> { render_error(:too_many_requests, t('chapters.markdown_imports.errors.rate_limited')) }
    before_action :authorize_import

    def create
      markdown = params[:markdown].to_s
      return render_error(:unprocessable_content, t('chapters.markdown_imports.errors.blank')) if markdown.blank?
      return render_error(:content_too_large, too_large_message) if markdown.bytesize > MAX_BYTES

      result = ApiContentSanitizer.call(MarkdownToHtml.call(markdown))
      render json: { html: result.html, changes: result.changes }
    end

    private

    def authorize_import
      return if current_user.admin? || current_user.scanlators.exists?

      render_error(:forbidden, t('chapters.markdown_imports.errors.forbidden'))
    end

    def too_large_message
      t('chapters.markdown_imports.errors.too_large', max: MAX_BYTES / 1.megabyte)
    end

    def render_error(status, message)
      render json: { error: message }, status:
    end
  end
end
