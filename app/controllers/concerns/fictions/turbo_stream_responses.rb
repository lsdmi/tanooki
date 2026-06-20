# frozen_string_literal: true

module Fictions
  # Turbo Stream responses for fiction chapter sorting and dashboard list refresh.
  module TurboStreamResponses
    extend ActiveSupport::Concern

    private

    def render_sorted_chapters
      render turbo_stream: sorted_chapters_turbo_streams
    end

    def sorted_chapters_turbo_streams
      locals = sorted_chapters_frame_locals
      turbo_stream_with_cleared_flash(
        turbo_stream.update(sorted_chapters_frame_dom_id, partial: 'fictions/chapters', locals: locals)
      )
    end

    def sorted_chapters_frame_locals
      locals = @show_presenter.sorted_chapters_locals
      return locals unless reader_drawer_chapter_sort?

      locals.merge(
        toggle_order_button_id: 'toggle-fictions-order-drawer',
        reader_drawer: true,
        current_chapter: current_chapter_for_reader_drawer_sort
      )
    end

    def sorted_chapters_frame_dom_id
      reader_drawer_chapter_sort? ? 'sort-chapters-reader-drawer' : 'sort-chapters'
    end

    def reader_drawer_chapter_sort?
      ActiveModel::Type::Boolean.new.cast(params[:reader_drawer])
    end

    def current_chapter_for_reader_drawer_sort
      return nil if params[:current_chapter_id].blank?

      Chapter.find_by(id: params[:current_chapter_id])
    end

    def toggle_order_params
      params.merge(order: params[:order].to_sym == :desc ? :asc : :desc)
    end

    def refresh_list
      turbo_stream.update(
        'fictions-list',
        partial: 'users/dashboard/fictions',
        locals: { fictions: @fictions, pagy: @pagy }
      )
    end

    def details_partial
      if request.referer == alphabetical_fictions_url || request.referer&.include?('/bookshelves/')
        'fiction_lists/fiction_details'
      else
        'fictions/fiction_details'
      end
    end
  end
end
