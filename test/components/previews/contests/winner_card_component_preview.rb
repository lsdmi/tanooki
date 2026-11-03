# frozen_string_literal: true

module Contests
  class WinnerCardComponentPreview < ViewComponent::Preview
    layout 'component_preview'

    def default
      award = ContestAward.includes(:contest, :contest_prize,
                                    contest_entry: { fiction: { cover_attachment: :blob } }).first
      return render_missing('Немає нагород у БД') if award.blank?

      render(WinnerCardComponent.new(award:, show_aftermath: true))
    end

    private

    def render_missing(message)
      render_with_template(template: 'contests/missing_message', locals: { message: })
    end
  end
end
