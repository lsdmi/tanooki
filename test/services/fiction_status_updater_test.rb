# frozen_string_literal: true

require 'test_helper'

class FictionStatusUpdaterTest < ActiveSupport::TestCase
  setup do
    @fiction = fictions(:one)
    @user = users(:user_one)
    @scanlator = scanlators(:one)
    @valid_content = 'a' * 500
  end

  def create_chapter(attrs = {})
    @fiction.chapters.create!(
      title: attrs[:title] || 'Test Chapter',
      number: attrs[:number] || 1,
      created_at: attrs[:created_at] || Time.current,
      user: @user,
      content: @valid_content,
      scanlator_ids: [@scanlator.id]
    )
  end

  test 'does nothing if fiction is finished' do
    @fiction.update_column(:status, 'Завершено')  # finished
    assert_no_changes -> { @fiction.reload.status } do
      FictionStatusUpdater.new(@fiction).call
    end
  end

  test 'does nothing if last chapter is recent' do
    @fiction.update_column(:status, 'Видається')  # ongoing
    create_chapter(created_at: 1.day.ago, number: 1)
    assert_no_changes -> { @fiction.reload.status } do
      FictionStatusUpdater.new(@fiction).call
    end
  end

  test 'sets status to dropped if last chapter is older than 90 days' do
    @fiction.update_column(:status, 'Видається')  # ongoing
    @fiction.chapters.update_all(created_at: 100.days.ago) # force the timestamp
    FictionStatusUpdater.new(@fiction).call
    assert_equal 'dropped', @fiction.reload.status # dropped
  end

  test 'does nothing if fiction has no chapters' do
    @fiction.update_column(:status, 'Видається') # ongoing
    @fiction.chapters.destroy_all
    assert_no_changes -> { @fiction.reload.status } do
      FictionStatusUpdater.new(@fiction).call
    end
  end
end
