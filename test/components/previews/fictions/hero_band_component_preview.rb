# frozen_string_literal: true

module Fictions
  # Uses the development database: the hero needs a real cover, teams and chapter routes.
  class HeroBandComponentPreview < ViewComponent::Preview
    # @label Logged out
    def logged_out
      render hero(user: nil)
    end

    # @label Logged in
    def logged_in
      render hero(user: sample_progress&.user || User.first)
    end

    # @label With notices (16+ over «no new chapters»)
    def with_notice
      render(hero(user: nil)) do |component|
        component.with_notice do
          component.helpers.safe_join(%i[teen dropped].map do |kind|
            Ui::NoticeComponent.new(style: :scrim, html: { class: 'mb-2' }, **Fictions::NoticeZone.notice(kind).to_h)
                               .render_in(component)
          end)
        end
      end
    end

    private

    def hero(user:)
      fiction = sample_progress&.fiction || Fiction.joins(:cover_attachment).order(views: :desc).first
      Fictions::HeroBandComponent.new(fiction:, presenter: FictionShowPresenter.new(fiction, user), user:)
    end

    def sample_progress
      @sample_progress ||= ReadingProgress.joins(fiction: :cover_attachment).order(updated_at: :desc).first
    end
  end
end
