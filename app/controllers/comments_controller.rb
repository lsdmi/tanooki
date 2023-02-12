# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :set_comment, only: %i[show edit update destroy cancel_edit cancel_reply]

  def new
    @comment = Comment.new(comment_params)
    @tale = @comment.commentable
  end

  def create
    @tale = Tale.find_by(id: comment_params[:commentable_id])
    @created_comment = Comment.create(comment_params)

    update_parent

    @new_comment = Comment.new
  end

  def destroy
    @comment.destroy
  end

  def edit
    @tale = @comment.commentable
  end

  def cancel_edit
    render 'complete_update'
  end

  def cancel_reply
    @tale = @comment.commentable
  end

  def update
    @comment.update(comment_params)

    render 'complete_update'
  end

  private

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
