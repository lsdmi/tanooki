# frozen_string_literal: true

require 'test_helper'

module Fictions
  class DuplicateGroupsTest < ActiveSupport::TestCase
    test 'normalize keeps letters and digits and drops punctuation and case' do
      assert_equal 'тисячаосеней', DuplicateGroups.normalize('  Тисяча осеней! ')
      assert_equal 'rezero2', DuplicateGroups.normalize('Re:Zero 2')
      assert_equal '', DuplicateGroups.normalize('— …')
    end

    test 'groups fictions when any title field matches after normalization' do
      left = listed('dup-left', title: 'Hello, World!', english_title: 'Unrelated')
      right = listed('dup-right', title: 'Something else', alternative_title: 'hello world')

      group = DuplicateGroups.new.call.find { |rows| rows.map(&:slug).include?(left.slug) }

      assert_equal [left.slug, right.slug].sort, group.map(&:slug).sort
    end

    test 'connects a chain of matches into one group' do
      first = listed('chain-a', title: 'Alpha Tale')
      second = listed('chain-b', title: 'Beta Tale', english_title: 'Alpha Tale')
      third = listed('chain-c', title: 'Gamma Tale', alternative_title: 'beta tale')

      group = DuplicateGroups.new.call.find { |rows| rows.map(&:slug).include?('chain-a') }

      assert_equal [first.slug, second.slug, third.slug].sort, group.map(&:slug).sort
    end

    test 'does not group on a blank title field' do
      listed('blank-a', title: 'Only Alpha', alternative_title: '')
      listed('blank-b', title: 'Only Beta', english_title: nil)

      slugs = DuplicateGroups.new.call.flatten.map(&:slug)

      assert_not_includes slugs, 'blank-a'
      assert_not_includes slugs, 'blank-b'
    end

    test 'skips a soft-deleted fiction' do
      listed('gone-a', title: 'Shared Novel')
      gone = listed('gone-b', title: 'Shared Novel')
      gone.destroy!

      slugs = DuplicateGroups.new.call.flatten.map(&:slug)

      assert_not_includes slugs, 'gone-a'
      assert_not_includes slugs, 'gone-b'
    end

    test 'reports teams chapter count readers and created date' do
      fiction = fictions(:one)
      other = fictions(:two)
      assign_titles(fiction, title: 'Same Work')
      assign_titles(other, title: 'Інша назва', english_title: 'Same Work!')

      rows = DuplicateGroups.new.call.flatten.index_by(&:slug)
      row = rows.fetch('one')

      assert_equal ['One', fiction.chapter_count, 1, fiction.created_at.to_date],
                   [row.teams, row.chapters, row.readers, row.created_on]
      assert_equal 2, rows.fetch('two').readers
    end

    private

    def listed(slug, **attributes)
      defaults = { slug:, title: slug, author: 'Author Name', description: 'd' * 30, chapter_count: 3 }
      fiction = Fiction.new(defaults.merge(attributes))
      fiction.save!(validate: false)
      FictionScanlator.create!(fiction:, scanlator: scanlators(:two))
      fiction
    end

    def assign_titles(fiction, **attributes)
      fiction.assign_attributes(alternative_title: nil, english_title: nil, **attributes)
      fiction.save!(validate: false)
    end
  end
end
