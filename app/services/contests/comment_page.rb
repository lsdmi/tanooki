# frozen_string_literal: true

module Contests
  # One page of top-level contest comments, newest first, with a lookahead row for the «show more» button.
  class CommentPage
    PAGE_SIZE = 5

    def initialize(contest, page:)
      @contest = contest
      @page = [page.to_i, 1].max
    end

    def comments
      loaded.first(PAGE_SIZE)
    end

    def more? = loaded.size > PAGE_SIZE

    attr_reader :page

    def next_page = page + 1

    private

    attr_reader :contest

    def loaded
      @loaded ||= contest.comments.parents
                         .includes(
                           { user: { avatar: :image_attachment } },
                           replies: { user: { avatar: :image_attachment } }
                         )
                         .order(created_at: :desc, id: :desc)
                         .offset((page - 1) * PAGE_SIZE)
                         .limit(PAGE_SIZE + 1)
                         .to_a
    end
  end
end
