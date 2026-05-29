# frozen_string_literal: true

require 'test_helper'

module Library
  class ReadingStateTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
    end

    test 'fiction_epub_download_support is all when every listable chapter allows epub' do
      assert_equal :all, ReadingState.fiction_epub_download_support(@fiction, viewer: nil)
    end

    test 'fiction_epub_download_support is none when no listable chapter allows epub' do
      sl = scanlators(:one)
      sl.convertable = false
      sl.save(validate: false)

      assert_equal :none, ReadingState.fiction_epub_download_support(@fiction, viewer: nil)
    ensure
      sl = scanlators(:one)
      sl.convertable = true
      sl.save(validate: false)
    end

    test 'fiction_epub_download_support is mixed when some chapters allow epub and some do not' do
      s2 = scanlators(:two)
      s2.convertable = false
      s2.save(validate: false)
      chapter_two = chapters(:two)
      chapter_two.chapter_scanlators.destroy_all
      Chapters::SyncScanlatorAssociations.new([s2.id.to_s], chapter_two.reload).call

      assert_equal :mixed, ReadingState.fiction_epub_download_support(@fiction, viewer: nil)
    ensure
      s2 = scanlators(:two)
      s2.convertable = true
      s2.save(validate: false)
      chapter_two = chapters(:two)
      chapter_two.reload.chapter_scanlators.destroy_all
      Chapters::SyncScanlatorAssociations.new([scanlators(:one).id.to_s], chapter_two).call
    end
  end
end
