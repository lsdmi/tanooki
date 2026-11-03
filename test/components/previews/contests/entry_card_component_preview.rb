# frozen_string_literal: true

module Contests
  class EntryCardComponentPreview < ViewComponent::Preview
    layout 'component_preview'

    # @label Uses the first fiction with a cover when present
    def default
      fiction = Fiction.with_attached_cover.order(:id).first
      return render_missing('Немає творів із обкладинкою в БД') if fiction.blank?

      entry = ContestEntry.new(fiction:)
      render(EntryCardComponent.new(entry:))
    end

    # @label 18+ blurred
    def eighteen_blurred
      fiction = Fiction.with_attached_cover.order(:id).first
      return render_missing('Немає творів із обкладинкою в БД') if fiction.blank?

      entry = ContestEntry.new(fiction:)
      render(EntryCardComponent.new(entry:, blur_eighteen: true))
    end

    private

    def render_missing(message)
      render_with_template(template: 'contests/missing_message', locals: { message: })
    end
  end
end
