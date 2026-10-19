# frozen_string_literal: true

require 'test_helper'

module Meta
  class FictionSeoTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @fiction.scanlators.clear
      @fiction.english_title = nil
      @fiction.alternative_title = nil
      @fiction.short_description = nil
    end

    test 'page_title includes ранобе українською and Бака' do
      title = FictionSeo.new(@fiction).page_title

      assert_equal 'Test Fiction | Ранобе українською | Бака', title
    end

    test 'page_title includes english_title when the result stays short' do
      @fiction.english_title = 'Short EN'

      title = FictionSeo.new(@fiction).page_title

      assert_equal 'Test Fiction (Short EN) | Ранобе українською | Бака', title
    end

    test 'page_title omits long english_title from the head' do
      @fiction.english_title = 'A Very Long English Title That Would Blow Past Seventy Characters Easily'

      title = FictionSeo.new(@fiction).page_title

      assert_equal 'Test Fiction | Ранобе українською | Бака', title
      assert_includes FictionSeo.new(@fiction).meta_description, @fiction.english_title
    end

    test 'meta_description prefers short_description and read tail' do
      @fiction.short_description = 'Короткий опис твору для пошуку.'

      description = FictionSeo.new(@fiction).meta_description

      assert_equal 'Короткий опис твору для пошуку. Читати українською на Баці · автор «Test Author».', description
    end

    test 'meta_description stays within SERP length' do
      @fiction.english_title = 'Lord of the Mysteries'
      @fiction.description = ('Дія відбувається у світі таємниць. ' * 20)

      description = FictionSeo.new(@fiction).meta_description

      assert_operator description.length, :<=, FictionSeo::MAX_DESCRIPTION_LENGTH
    end

    test 'meta_description skips announcement prefixes in the blurb' do
      @fiction.description = "ЗУПИНКА ПЕРЕКЛАДУ!\n\nСправжнє перше речення про сюжет."

      description = FictionSeo.new(@fiction).meta_description

      assert_includes description, 'Справжнє перше речення про сюжет.'
      assert_not_includes description, 'ЗУПИНКА'
    end

    test 'meta_description names at most two scanlator teams' do
      teams = [
        Struct.new(:title).new('Alpha Team'),
        Struct.new(:title).new('Beta Team'),
        Struct.new(:title).new('Gamma Team')
      ]
      @fiction.define_singleton_method(:scanlators) { teams }

      description = FictionSeo.new(@fiction).meta_description

      assert_match(/Alpha Team.*Beta Team.*та ін\./, description)
      assert_not_includes description, 'Gamma Team'
    end

    test 'alternate_names lists english and alternative titles' do
      @fiction.english_title = 'Lord of the Mysteries'
      @fiction.alternative_title = '诡秘之主'

      assert_equal ['Lord of the Mysteries', '诡秘之主'], FictionSeo.new(@fiction).alternate_names
    end
  end
end
