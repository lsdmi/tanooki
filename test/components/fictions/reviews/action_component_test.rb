# frozen_string_literal: true

require 'test_helper'

module Fictions
  module Reviews
    class ActionComponentTest < ViewComponentTestCase
      LONG_TEXT = 'Дуже сподобався сюжет і переклад, герої живі, а світ продуманий до дрібниць. ' \
                  'Чекаю продовження й дякую команді за роботу.'

      setup do
        @fiction = fictions(:two)
        @reader = users('user_101')
        @comment = Comment.create!(user: @reader, commentable: @fiction, content: LONG_TEXT)
        FictionRating.create!(user: @reader, fiction: @fiction, rating: 4)
      end

      test 'a reader with a rating and a long comment can mark it' do
        render_component(@comment.reload, user: @reader)

        assert_selector %(a[href="/comments/#{@comment.id}/review"][data-turbo-method="post"]),
                        text: 'Позначити як відгук'
      end

      test 'the mark carries the order and filter of the list it sits in' do
        render_inline(ActionComponent.new(comment: @comment.reload, fiction: @fiction, user: @reader,
                                          list_state: { order: :asc, reviews_only: true }))

        assert_selector %(a[href="/comments/#{@comment.id}/review?filter=reviews&order=asc"][data-turbo-method="post"])
      end

      test 'the mark without list state carries no query' do
        render_component(@comment.reload, user: @reader)

        assert_selector %(a[href="/comments/#{@comment.id}/review"][data-turbo-method="post"])
      end

      test 'a comment that is a review offers to take the mark off' do
        FictionReview.create!(comment: @comment, user: @reader, fiction: @fiction)

        render_component(@comment.reload, user: @reader)

        assert_selector %(a[href="/comments/#{@comment.id}/review"][data-turbo-method="delete"]), text: 'Зняти позначку'
        assert_no_selector 'a[data-turbo-method="post"]'
      end

      test 'without a rating the reader is told to rate the fiction first' do
        FictionRating.where(user: @reader).delete_all

        render_component(@comment.reload, user: @reader)

        assert_no_selector 'a'
        assert_text 'Спочатку поставте оцінку цьому твору'
      end

      test 'a short comment says how long it has to be' do
        short = Comment.create!(user: @reader, commentable: @fiction, content: 'Коротко, але сподобалось')

        render_component(short, user: @reader)

        assert_text 'потрібно щонайменше 100 символів'
        assert_no_selector 'a'
      end

      test 'a second review is blocked with a disabled button and the reason' do
        first = Comment.create!(user: @reader, commentable: @fiction, content: LONG_TEXT)
        FictionReview.create!(comment: first, user: @reader, fiction: @fiction)

        render_component(@comment.reload, user: @reader)

        assert_selector 'button[disabled]', text: 'Позначити як відгук'
        assert_text 'Ви вже лишали відгук на цей твір'
      end

      test 'a team member with a rating may mark their own comment' do
        team_member = users(:user_two)
        ScanlatorUser.create!(scanlator: scanlators(:one), user: team_member)
        FictionRating.create!(user: team_member, fiction: @fiction, rating: 5)
        own = Comment.create!(user: team_member, commentable: @fiction, content: LONG_TEXT)

        render_component(own, user: team_member)

        assert_selector %(a[data-turbo-method="post"]), text: 'Позначити як відгук'
      end

      test 'an admin can take the mark off a review that is not theirs' do
        FictionReview.create!(comment: @comment, user: @reader, fiction: @fiction)

        render_component(@comment.reload, user: users(:user_one))

        assert_selector 'a[data-turbo-method="delete"]', text: 'Зняти позначку'
      end

      test 'another reader sees no control on someone else’s review' do
        FictionReview.create!(comment: @comment, user: @reader, fiction: @fiction)

        render_component(@comment.reload, user: users(:user_two))

        assert_predicate rendered_content.strip, :empty?
      end

      test 'a guest gets nothing' do
        render_component(@comment, user: nil)

        assert_predicate rendered_content.strip, :empty?
      end

      test 'a reply cannot be a review' do
        reply = Comment.create!(user: @reader, commentable: @fiction, parent: @comment, content: LONG_TEXT)

        render_component(reply, user: @reader)

        assert_predicate rendered_content.strip, :empty?
      end

      test 'a chapter comment gets no review control' do
        chapter_comment = Comment.create!(user: @reader, commentable: chapters(:two), content: LONG_TEXT)

        render_component(chapter_comment, user: @reader)

        assert_predicate rendered_content.strip, :empty?
      end

      private

      def render_component(comment, user:)
        render_inline(ActionComponent.new(comment:, fiction: comment.commentable, user:))
      end
    end
  end
end
