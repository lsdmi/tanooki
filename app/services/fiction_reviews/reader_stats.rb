# frozen_string_literal: true

module FictionReviews
  # What a review shows about its author on one fiction: the author's rating and how many chapters they read.
  # Both come in one query for the whole batch, so a page of reviews does not ask once per review.
  class ReaderStats
    def initialize(fiction:, user_ids:)
      @fiction = fiction
      @user_ids = user_ids.uniq
    end

    def rating_for(user_id) = ratings[user_id]

    def read_count_for(user_id) = read_counts.fetch(user_id, 0)

    private

    def ratings
      @ratings ||= if @user_ids.empty?
                     {}
                   else
                     FictionRating.where(fiction: @fiction, user_id: @user_ids).pluck(:user_id, :rating).to_h
                   end
    end

    # Every source counts, including manual marks: the number is what the reader read, not how they did it.
    def read_counts
      @read_counts ||= if @user_ids.empty?
                         {}
                       else
                         ReadingChapterRead.where(fiction_id: @fiction.id, user_id: @user_ids).group(:user_id).count
                       end
    end
  end
end
