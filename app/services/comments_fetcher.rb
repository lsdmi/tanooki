# frozen_string_literal: true

class CommentsFetcher
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def collect
    (blog_comments + chapter_comments + fiction_comments + threads).sort_by(&:id).reverse.uniq
  end

  private

  def blog_comments
    Comment.where(commentable_type: 'Publication')
           .joins('INNER JOIN publications ON comments.commentable_id = publications.id')
           .where('publications.user_id = ?', user.id)
           .where.not(comments: { user_id: user.id })
  end

  def chapter_comments
    chapter_ids = Chapter.joins(:scanlators).where(scanlators: { id: user.scanlators }).pluck(:id)
    Comment.where(commentable_id: chapter_ids, commentable_type: 'Chapter')
           .where.not(user_id: user.id)
  end

  def fiction_comments
    fiction_ids = Fiction.joins(:scanlators).where(scanlators: { id: user.scanlators }).pluck(:id)
    Comment.where(commentable_id: fiction_ids, commentable_type: 'Fiction')
           .where.not(user_id: user.id)
  end

  def threads
    Comment.where.not(user_id: user.id).where(parent_id: user.comments)
  end
end
