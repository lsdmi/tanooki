# frozen_string_literal: true

require 'test_helper'

module FictionTags
  class NormalizerTest < ActiveSupport::TestCase
    test 'squishes whitespace and strips leading hashes' do
      assert_equal 'пригода у часі', Normalizer.name("  #пригода \n у   часі ")
    end

    test 'preserves case' do
      assert_equal 'ЛітРПГ', Normalizer.name('ЛітРПГ')
    end

    test 'unifies apostrophes and ё' do
      assert_equal 'пам’ять', Normalizer.name("пам'ять")
      assert_equal 'пам’ять', Normalizer.name('памʼять')
      assert_equal 'Еж', Normalizer.name('Ёж')
    end

    test 'returns empty string for nil' do
      assert_equal '', Normalizer.name(nil)
    end

    test 'slug transliterates Ukrainian and ignores case and apostrophe style' do
      assert_equal 'pererodzhennia', Normalizer.slug('Переродження')
      assert_equal Normalizer.slug("пам'ять"), Normalizer.slug('ПАМʼЯТЬ')
    end

    test 'unique_names dedupes by slug keeping the first spelling and dropping blanks' do
      names = Normalizer.unique_names(['Переродження', ' переродження ', '#', '', "пам'ять", 'Памʼять'])

      assert_equal ['Переродження', 'пам’ять'], names
    end
  end
end
