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
           .joins("INNER JOIN publications ON comments.commentable_id = publications.id")
           .where("publications.user_id = ?", user.id)
           .where.not(comments: { user_id: user.id })
           .includes([:commentable , { user: { avatar: { image_attachment: :blob } } }])
  end

  def chapter_comments
    chapter_ids = Chapter.joins(:scanlators).where(scanlators: { id: user.scanlators }).pluck(:id)
    Comment.where(commentable_id: chapter_ids, commentable_type: 'Chapter')
           .where.not(user_id: user.id)
           .includes([{ commentable: :fiction }, { user: { avatar: { image_attachment: :blob } } }])
  end

  def fiction_comments
    fiction_ids = Fiction.joins(:scanlators).where(scanlators: { id: user.scanlators }).pluck(:id)
    Comment.where(commentable_id: fiction_ids, commentable_type: 'Fiction')
           .where.not(user_id: user.id)
           .includes([:commentable , { user: { avatar: { image_attachment: :blob } } }])
  end

  def threads
    grouped_comments = Comment.select(:commentable_id, :commentable_type)
                              .where(user_id: user.id)
                              .group(:commentable_id, :commentable_type)
                              .having("COUNT(*) > 1")

    grouped_ids_and_types = grouped_comments.pluck(:commentable_id, :commentable_type)

    Comment.where.not(user_id: user.id)
           .where(commentable_id: grouped_ids_and_types.map(&:first))
           .where(commentable_type: grouped_ids_and_types.map(&:second))
           .includes([:commentable , { user: { avatar: { image_attachment: :blob } } }])
  end
end