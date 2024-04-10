# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :load_advertisement, only: :index
  before_action :set_comment, only: %i[show edit update destroy cancel_edit cancel_reply]

  def index
    @pagy, @comments = pagy_countless(comments, items: 40)

    render 'comments/scrollable_list' if params[:page]
  end

  def new
    @comment = Comment.new(comment_params)
    @commentable = @comment.commentable
  end

  def create
    @created_comment = Comment.create(comment_params)
    @commentable = @created_comment.commentable

    update_parent

    @new_comment = Comment.new
  end

  def destroy
    @comment.destroy
  end

  def edit
    @commentable = @comment.commentable
  end

  def cancel_edit
    render 'complete_update'
  end

  def cancel_reply
    @commentable = @comment.commentable
  end

  def update
    @comment.update(comment_params)

    render 'complete_update'
  end

  def dropdown
    current_user.update(latest_read_comment_id: latest_comments.first.id)
  end

  private

  def comments
    Rails.cache.fetch('all_comments', expires_in: 1.hour) do
      Comment.includes(
        [{ commentable: { cover_attachment: :blob } }, { user: { avatar: { image_attachment: :blob } } }]
      ).order(id: :desc)
    end
  end

  def set_comment
    @comment = Comment.find_by(id: params[:id] || params[:comment_id])
  end

  def comment_params
    params.require(:comment).permit(:content, :commentable_id, :commentable_type, :user_id, :parent_id)
  end

  def update_parent
    return unless comment_params[:parent_id].present?

    @reply_parent = Comment.find_by(id: comment_params[:parent_id])

    return unless @reply_parent.parent_id.present?

    @created_comment.update(parent_id: @reply_parent.parent_id)
  end
end
