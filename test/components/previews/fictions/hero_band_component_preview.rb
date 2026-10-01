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

    # @label With notice
    def with_notice
      render(hero(user: nil)) do |component|
        component.with_notice do
          Ui::NoticeComponent.new(kind: :adult, style: :scrim, title: 'Контент 18+',
                                  body: 'Цей твір містить матеріали для дорослої аудиторії.').render_in(component)
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
