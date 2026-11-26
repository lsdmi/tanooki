# frozen_string_literal: true

module FictionShow
  # The comments tab of fiction#show: one page of top-level comments, the order, the page, and the «Відгуки» filter.
  # The order and page come from the comments frame URL, so guests stay cacheable.
  class CommentsThread
    def initialize(fiction, params)
      @fiction = fiction
      @params = params
    end

    def comments = page_with_lookahead.first(FictionShowPresenter::COMMENTS_PAGE_SIZE)

    def more_comments? = page_with_lookahead.size > FictionShowPresenter::COMMENTS_PAGE_SIZE

    def comments_order = @params[:order].to_s == 'asc' ? :asc : :desc

    def comments_page = [@params[:page].to_i, 1].max

    def new_comment = @new_comment ||= Comment.new

    # Only comments that are reviews; the order and paging stay the same.
    def reviews_only? = @params[:filter].to_s == 'reviews'

    # Sent back with a mark or unmark, so the filter can be redrawn for the list the reader is looking at.
    def list_state = { order: comments_order, reviews_only: reviews_only? }

    # Author rating and read count for the reviews on this page, loaded once for the whole page.
    def review_stats
      @review_stats ||= FictionReviews::ReaderStats.new(
        fiction: @fiction,
        user_ids: comments.filter_map { |comment| comment.user_id if comment.fiction_review }
      )
    end

    private

    def page_with_lookahead
      @page_with_lookahead ||= scope
                               .includes({ user: { avatar: :image_attachment } }, :fiction_review,
                                         replies: { user: { avatar: :image_attachment } })
                               .order(created_at: comments_order, id: comments_order)
                               .offset((comments_page - 1) * FictionShowPresenter::COMMENTS_PAGE_SIZE)
                               .limit(FictionShowPresenter::COMMENTS_PAGE_SIZE + 1).to_a
    end

    def scope
      parents = @fiction.comments.parents
      return parents unless reviews_only?

      parents.where(id: FictionReview.where(fiction: @fiction).select(:comment_id))
    end
  end
end
