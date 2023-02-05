class CommentsController < ApplicationController
  before_action :set_comment, only: %i[show destroy]

  def create
    @tale = Tale.find_by(comment_params[:commentable_id])
    @comment = Comment.create(comment_params)
  end

  def destroy
    @comment.destroy
  end

  private

  def set_comment
    @comment = Comment.find_by(id: params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content, :commentable_id, :commentable_type, :user_id)
  end
end
