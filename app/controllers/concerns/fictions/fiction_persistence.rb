# frozen_string_literal: true

module Fictions
  # Shared create/update flow for fiction forms and association sync.
  module FictionPersistence
    extend ActiveSupport::Concern

    private

    def persist_fiction(sync_class, failure_template, notice)
      form = FictionForm.new(fiction: @fiction, params: fiction_params)
      if form.save
        sync_fiction_associations(sync_class)
        redirect_to @fiction, notice: notice
      else
        render failure_template, status: :unprocessable_content
      end
    end

    def sync_fiction_associations(sync_class)
      sync_class.new(
        @fiction,
        genre_ids: fiction_params[:genre_ids],
        scanlator_ids: fiction_params[:scanlator_ids],
        user: current_user
      ).call
    end

    def fiction_params
      params.expect(
        fiction: [
          :alternative_title, :author, :cover, :description, :english_title, :origin,
          :status, :title, :total_chapters, :short_description, :banner, :adult_content,
          { genre_ids: [], scanlator_ids: [] }
        ]
      )
    end
  end
end
