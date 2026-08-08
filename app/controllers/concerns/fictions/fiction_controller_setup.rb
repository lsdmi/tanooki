# frozen_string_literal: true

module Fictions
  # Shared before_action callbacks and private helpers for {FictionsController}.
  module FictionControllerSetup
    extend ActiveSupport::Concern

    private

    def set_fiction
      @fiction = @commentable = Fiction.includes(
        :genres, :scanlators, :fiction_ratings, cover_attachment: :blob
      ).find(params.expect(:id))
      @commentable = @fiction
    end

    def adsense_allowed?
      return false if fiction_ads_fully_excluded?

      super
    end

    def fiction_ads_fully_excluded?
      @fiction&.slug.in?(self.class::AD_EXCLUDED_SLUGS)
    end

    def set_genres
      @genres = Genre.order(:name)
    end

    def authorize_fiction
      policy = Fictions::Authorization.new(current_user, @fiction)
      redirect_to root_path unless policy.edit?
    end

    def authorize_fiction_creation
      policy = Fictions::Authorization.new(current_user, nil)
      redirect_to new_scanlator_path unless policy.create?
    end

    def render_fiction_show_fragment
      @show_presenter = FictionShowPresenter.new(@fiction, current_user, params)
      render layout: false
    end
  end
end
