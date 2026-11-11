# frozen_string_literal: true

module Scanlators
  # Public scanlator show: paginated works catalog + Turbo frame partial.
  module ShowCatalog
    extend ActiveSupport::Concern

    WORKS_PAGE_SIZE = 24

    private

    def prepare_scanlator_show
      @scanlator_stats = Scanlators::ShowPresenter.new(@scanlator)
      @pagy, @fictions = paginated_scanlator_works

      if turbo_frame_request_id == WorksCatalogHelper::WORKS_FRAME_ID
        render_scanlator_works_frame
      else
        @members = @scanlator.users.includes(avatar: :image_attachment).order(:name)
      end
    end

    def render_scanlator_works_frame
      render partial: 'scanlators/works_catalog',
             locals: { fictions: @fictions, pagy: @pagy, scanlator: @scanlator }
    end

    def paginated_scanlator_works
      pagy(
        FictionListQueryBuilder.new(
          @scanlator.fictions_with_published_chapters,
          q: params[:q].is_a?(String) ? params[:q] : nil,
          sort: WorksCatalogHelper.normalize_sort(params[:sort])
        ).call,
        limit: WORKS_PAGE_SIZE
      )
    end
  end
end
