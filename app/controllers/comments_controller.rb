# frozen_string_literal: true

# Handles authenticated comment creation, replies, editing, and deletion.
class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_comment, only: %i[edit update destroy cancel_edit cancel_reply]
  before_action :authorize_comment_owner!, only: %i[edit update destroy cancel_edit]

  def new
    @comment = Comment.new(new_comment_params)
    @commentable = @comment.commentable
  end

  def edit
    @commentable = @comment.commentable
  end

  def create
    comment_params = create_comment_params
    @created_comment = current_user.comments.create(comment_params)
    @commentable = @created_comment.commentable

    update_parent(comment_params[:parent_id])

    @new_comment = Comment.new
  end

  def update
    @comment.update(update_comment_params)

    render 'complete_update'
  end

  def destroy
    @commentable = @comment.commentable
    @comment.destroy
  end

  def cancel_edit
    render 'complete_update'
  end

  def cancel_reply
    @commentable = @comment.commentable
  end

  private

  def set_comment
    @comment = Comment.find(params[:id] || params[:comment_id])
  end

  def authorize_comment_owner!
    return if current_user.admin? || current_user.comments.exists?(id: @comment.id)

    head :forbidden
  end

  def new_comment_params
    params.expect(comment: %i[commentable_id commentable_type parent_id])
  end

  def create_comment_params
    params.expect(comment: %i[content commentable_id commentable_type parent_id])
  end

  def update_comment_params
    params.expect(comment: [:content])
  end

  def update_parent(parent_id)
    return if parent_id.blank?

    @reply_parent = Comment.find_by(id: parent_id)

    return if @reply_parent&.parent_id.blank?

    @created_comment.update(parent_id: @reply_parent.parent_id)
  end
end
