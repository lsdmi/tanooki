# frozen_string_literal: true

require 'test_helper'

module FictionTags
  class SyncTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @rebirth = fiction_tags(:rebirth)
      @litrpg = fiction_tags(:litrpg)
    end

    test 'does nothing when no names are submitted' do
      @fiction.fiction_tags << @rebirth

      result = Sync.call(@fiction)

      assert_predicate result, :success?
      assert_equal [@rebirth], result.tags
    end

    test 'links submitted names and ignores blanks from the form' do
      result = Sync.call(@fiction, names: ['', 'Переродження', 'ЛітРПГ'])

      assert_predicate result, :success?
      assert_equal [@rebirth, @litrpg].sort_by(&:id), result.tags.sort_by(&:id)
      assert_equal 1, @rebirth.reload.fictions_count
    end

    test 'creates unknown names as active normalized tags' do
      result = Sync.call(@fiction, names: ['  #Академія   магії '])

      tag = FictionTag.find_by!(name: 'Академія магії')

      assert_predicate result, :success?
      assert_predicate tag, :active?
      assert_equal [tag], @fiction.reload.fiction_tags.to_a
    end

    test 'reuses an existing tag regardless of case and apostrophe style' do
      existing = FictionTag.create!(name: "пам'ять")

      assert_no_difference -> { FictionTag.count } do
        Sync.call(@fiction, names: %w[ПАМʼЯТЬ переродження])
      end
      assert_equal [existing, @rebirth].sort_by(&:id), @fiction.reload.fiction_tags.sort_by(&:id)
    end

    test 'dedupes names that collapse to one tag' do
      assert_difference -> { FictionTag.count }, 1 do
        Sync.call(@fiction, names: ['Магія', 'магія', ' МАГІЯ '])
      end
      assert_equal 1, @fiction.reload.fiction_tags.count
    end

    test 'removes links that are no longer submitted and updates the counter' do
      @fiction.fiction_tags << [@rebirth, @litrpg]

      Sync.call(@fiction, names: ['ЛітРПГ'])

      assert_equal [@litrpg], @fiction.reload.fiction_tags.to_a
      assert_equal 0, @rebirth.reload.fictions_count
      assert_equal 1, @litrpg.reload.fictions_count
    end

    test 'an empty submission clears the tags' do
      @fiction.fiction_tags << @rebirth

      Sync.call(@fiction, names: [])

      assert_empty @fiction.reload.fiction_tags
    end

    test 'touches the fiction only when the tag set changes' do
      stamp = @fiction.updated_at

      Sync.call(@fiction, names: ['Переродження'])
      changed = @fiction.reload.updated_at

      travel 1.minute do
        Sync.call(@fiction, names: ['Переродження'])
      end

      assert_operator changed, :>=, stamp
      assert_equal changed, @fiction.reload.updated_at
    end

    test 'rejects more than the per-fiction limit and writes nothing' do
      names = Array.new(FictionTag::MAX_PER_FICTION + 1) { |index| "Теґ номер #{index}" }

      assert_no_difference ['FictionTag.count', 'FictionTagLink.count'] do
        result = Sync.call(@fiction, names:)

        assert_equal [:too_many_tags], result.errors.map(&:code)
      end
    end

    test 'accepts exactly the per-fiction limit' do
      names = Array.new(FictionTag::MAX_PER_FICTION) { |index| "Теґ номер #{index}" }

      assert_predicate Sync.call(@fiction, names:), :success?
      assert_equal FictionTag::MAX_PER_FICTION, @fiction.reload.fiction_tags.count
    end

    test 'reports invalid names and rolls back the valid ones' do
      result = Sync.call(@fiction, names: ['Магія', '!!!', 'а' * 41])

      errors = result.errors.map { |error| [error.code, error.name] }

      assert_equal [[:invalid, '!!!'], [:too_long, 'а' * 41]], errors
      assert_nil FictionTag.find_by(name: 'Магія')
      assert_empty @fiction.reload.fiction_tags
    end

    test 'check reports unusable names and the limit without touching the database' do
      names = Array.new(FictionTag::MAX_PER_FICTION + 1) { |index| "Теґ номер #{index}" } + ['!!!', 'а' * 41]

      assert_no_difference 'FictionTag.count' do
        errors = Sync.check(names)

        assert_equal %i[invalid too_long too_many_tags], errors.map(&:code)
      end
    end

    test 'check counts one tag per slug and ignores blanks' do
      others = Array.new(FictionTag::MAX_PER_FICTION - 1) { |index| "Теґ #{index}" }

      assert_empty Sync.check(['', 'Магія', 'магія', ' МАГІЯ '] + others)
    end

    test 'does not newly attach a hidden tag' do
      result = Sync.call(@fiction, names: ['Юрі'])

      assert_predicate result, :success?
      assert_empty @fiction.reload.fiction_tags
    end

    test 'keeps a hidden tag the fiction already carries' do
      hidden = fiction_tags(:yuri_hidden)
      @fiction.fiction_tags << hidden

      Sync.call(@fiction, names: %w[Юрі Переродження])

      assert_equal [hidden, @rebirth].sort_by(&:id), @fiction.reload.fiction_tags.sort_by(&:id)
    end
  end
end
