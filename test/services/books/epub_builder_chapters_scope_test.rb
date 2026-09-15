# frozen_string_literal: true

require 'test_helper'

module Books
  class EpubBuilderChaptersScopeTest < ActiveSupport::TestCase
    test 'chapters_scope excludes drafts' do
      chapter = chapters(:one)
      rich_text = ActionText::RichText.find_by!(record: chapter, name: 'content')
      chapter.update!(status: :draft, scanlator_ids: chapter.scanlators.ids)

      assert_not_includes EpubBuilder.chapters_scope([rich_text.id]), chapter
    end

    test 'chapters_scope includes released chapters' do
      chapter = chapters(:one)
      rich_text = ActionText::RichText.find_by!(record: chapter, name: 'content')

      assert_includes EpubBuilder.chapters_scope([rich_text.id]), chapter
    end
  end
end
