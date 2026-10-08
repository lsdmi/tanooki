# frozen_string_literal: true

module Fictions
  # Shared create/update flow for fiction forms and association sync.
  module FictionPersistence
    extend ActiveSupport::Concern

    LICENSE_PARAMS = %i[licensed license_publisher license_url].freeze

    private

    def persist_fiction(failure_template, notice)
      form = FictionForm.new(fiction: @fiction, params: fiction_params, user: current_user)
      if form.save
        sync_fiction_associations
        flash[:alert] = t('fictions.license.clear_denied') if form.license_clear_denied?
        redirect_to @fiction, notice: notice
      else
        @title_matches = form.title_matches
        render failure_template, status: :unprocessable_content
      end
    end

    def sync_fiction_associations
      Fictions::SyncAssociations.new(
        @fiction,
        genre_ids: fiction_params[:genre_ids],
        scanlator_ids: fiction_params[:scanlator_ids],
        user: current_user
      ).call
    end

    def fiction_params
      return params.expect(fiction: LICENSE_PARAMS) if @fiction&.license_frozen_for?(current_user)

      params.expect(
        fiction: [
          :alternative_title, :author, :cover, :description, :english_title, :origin,
          :title, :expected_chapters, :complete, :short_description, :banner, :content_rating,
          :licensed, :license_publisher, :license_url, :chapters_hidden, :different_work,
          { genre_ids: [], scanlator_ids: [] }
        ]
      )
    end
  end
end
