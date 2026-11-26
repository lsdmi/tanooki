# frozen_string_literal: true

# Marks a comment as its author's review (create) and takes the mark off again (destroy). The comment stays in the
# thread either way; only the reader's review pointer changes. Turbo Stream only: the thread redraws the comment.
class CommentReviewsController < ApplicationController
  STATUSES = { not_owner: :forbidden, not_allowed: :forbidden }.freeze

  before_action :authenticate_user!
  # One bucket for mark and unmark: toggling back and forth is what the limit is for.
  rate_limit to: 10, within: 1.minute, by: -> { current_user.id },
             with: -> { render_rate_limited }
  before_action :set_comment
  before_action :authorize_author!, only: :create

  def create
    result = FictionReviews::Mark.call(comment: @comment, user: current_user)
    return render_error(result.error) unless result.ok

    render_comment(t('fictions.reviews.flash.marked'))
  end

  def destroy
    result = FictionReviews::Unmark.call(comment: @comment, user: current_user)
    return render_error(result.error) unless result.ok

    render_comment(t('fictions.reviews.flash.unmarked'))
  end

  private

  def set_comment
    @comment = Comment.find(params.expect(:comment_id))
  end

  # Checked before the service so a stranger gets 403 whatever their rating; Mark repeats the rule for the model.
  def authorize_author!
    render_error(:not_owner) unless @comment.user_id == current_user.id
  end

  def render_comment(notice)
    @comment.reload
    render turbo_stream: [
      *turbo_stream_notice(notice),
      turbo_stream.replace(@comment, partial: 'comments/comment',
                                     locals: { comment: @comment, commentable: @comment.commentable,
                                               list_state: }),
      *filter_stream
    ]
  end

  # The «Відгуки (N)» count moves with every mark, so the filter is redrawn in the order and filter the reader sent.
  def filter_stream
    fiction = @comment.commentable
    return [] unless fiction.is_a?(Fiction)

    component = Fictions::Reviews::FilterComponent.new(fiction:, order: list_state[:order],
                                                       reviews_only: list_state[:reviews_only])
    [turbo_stream.update('fiction_review_filter', view_context.render(component))]
  end

  # The order and filter of the list the reader sent with the request; the same ones the comment's links carry.
  def list_state
    { order: params[:order].to_s == 'asc' ? :asc : :desc, reviews_only: params[:filter].to_s == 'reviews' }
  end

  def render_error(reason)
    message = t("fictions.reviews.errors.#{reason}", count: FictionReview::MIN_LENGTH)
    render turbo_stream: turbo_stream_alert(message), status: STATUSES.fetch(reason, :unprocessable_content)
  end

  def render_rate_limited
    render turbo_stream: turbo_stream_alert(t('fictions.reviews.errors.rate_limited')), status: :too_many_requests
  end
end
