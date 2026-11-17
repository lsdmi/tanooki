# frozen_string_literal: true

module Bookshelves
  # Create/update fiction-id sync and selected-fiction loading for bookshelf forms.
  module FormActions
    extend ActiveSupport::Concern

    private

    def sync_bookshelf_fictions
      Bookshelves::SyncFictions.call(
        bookshelf: @bookshelf,
        fiction_ids: submitted_fiction_ids
      )
    end

    def submitted_fiction_ids
      return [] unless params[:bookshelf]&.key?(:fiction_ids)

      Array(params.dig(:bookshelf, :fiction_ids)).compact_blank
    end

    def load_selected_fictions
      ids = if params[:bookshelf]&.key?(:fiction_ids)
              Array(params.dig(:bookshelf, :fiction_ids)).compact_blank
            elsif @bookshelf&.persisted?
              @bookshelf.fictions.pluck(:id)
            else
              []
            end

      @selected_fictions = ids.any? ? Fiction.where(id: ids).order(:title) : Fiction.none
    end

    def refresh_list
      turbo_stream.update(
        'bookshelves-list',
        partial: 'studio/tabs/bookshelves',
        locals: { bookshelves: @bookshelves }
      )
    end
  end
end
