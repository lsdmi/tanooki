# frozen_string_literal: true

require 'test_helper'

module Api
  class AccessTest < ActiveSupport::TestCase
    setup do
      ChapterScanlator.create!(chapter: chapters(:three), scanlator: scanlators(:two))
      FictionScanlator.create!(fiction: fictions(:eighteen), scanlator: scanlators(:two))
    end

    test 'a member sees their own chapter and not another teams' do
      access = Access.new(users(:user_two))

      assert_equal chapters(:three), access.chapter(chapters(:three).id)
      assert_nil access.chapter(chapters(:one).id)
      assert_equal fictions(:eighteen), access.fiction('eighteen')
    end

    test 'an admin token does not see another teams chapter' do
      admin = users(:user_one)

      assert_predicate admin, :admin?
      assert admin.manages_chapter?(chapters(:three))
      assert_nil Access.new(admin).chapter(chapters(:three).id)
    end

    test 'an admin token does not see another teams fiction' do
      admin = users(:user_one)

      assert admin.manages_fiction?(fictions(:eighteen))
      assert_nil Access.new(admin).fiction(fictions(:eighteen).id)
      assert_nil Access.new(admin).fiction(fictions(:eighteen).slug)
    end

    test 'a revision is only reached through an accessible chapter' do
      access = Access.new(users(:user_two))

      assert_nil access.revision(chapters(:one).id, 1)
      assert_nil access.revision(chapters(:three).id, 99)
    end

    test 'leaving the team hides the chapter on the next call' do
      user = users(:user_two)
      access = Access.new(user)

      assert_equal chapters(:three).id, access.chapter!(chapters(:three).id).id

      user.scanlator_users.destroy_all

      assert_nil access.chapter(chapters(:three).id)
    end

    test 'every team id has to belong to the user' do
      access = Access.new(users(:user_two))
      own = scanlators(:two).id

      assert_equal [own], access.scanlator_ids!(fictions(:eighteen), [own.to_s])

      error = assert_raises(Error) { access.scanlator_ids!(fictions(:eighteen), [own, scanlators(:one).id]) }

      assert_equal 'scanlator_ids', error.code
    end

    test 'mixed team ids do not create a chapter' do
      before = Chapter.count

      assert_raises(Error) do
        Access.new(users(:user_two)).scanlator_ids!(fictions(:eighteen), [scanlators(:two).id, scanlators(:one).id])
      end
      assert_equal before, Chapter.count
    end

    test 'a published chapter needs the publish scope' do
      token = ApiToken.issue!(user: users(:user_two), name: 'Чернетки', scopes: %w[chapters:read chapters:write])
      error = assert_raises(Error) { Access.new(users(:user_two)).ensure_live_edit!(token, chapters(:three)) }

      assert_equal 'publish_scope', error.code
      assert_equal :forbidden, error.status
    end

    test 'a draft does not need the publish scope' do
      chapters(:three).update!(status: :draft)
      token = ApiToken.issue!(user: users(:user_two), name: 'Чернетки', scopes: %w[chapters:read chapters:write])

      assert_nothing_raised { Access.new(users(:user_two)).ensure_live_edit!(token, chapters(:three)) }
    end

    test 'the publish scope may edit a published chapter' do
      token = ApiToken.issue!(
        user: users(:user_two), name: 'Публікація', scopes: %w[chapters:read chapters:publish]
      )

      assert_nothing_raised { Access.new(users(:user_two)).ensure_live_edit!(token, chapters(:three)) }
    end

    test 'a licensed fiction rejects team ids' do
      fictions(:eighteen).update!(licensed_at: Time.current, license_publisher: 'Видавництво Тест')
      error = assert_raises(Error) do
        Access.new(users(:user_two)).scanlator_ids!(fictions(:eighteen), [scanlators(:two).id])
      end

      assert_equal 'licensed', error.code
    end
  end
end
