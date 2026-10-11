# frozen_string_literal: true

require 'test_helper'

class FictionsMergeRedirectTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:user_one)
    @source = build_fiction('merge-redirect-source', 'Джерело')
    @target = build_fiction('merge-redirect-target', 'Ціль')
  end

  test 'merged source url redirects to the surviving fiction' do
    Fictions::Merge.call(source: @source, target: @target, admin: @admin)

    get fiction_path(@source.slug)

    assert_response :moved_permanently
    assert_redirected_to fiction_path(@target)
  end

  private

  def build_fiction(slug, title)
    fiction = Fiction.new(slug:, title:, author: 'Автор', description: 'Опис твору достатньої довжини для тесту.')
    fiction.save!(validate: false)
    fiction
  end
end
