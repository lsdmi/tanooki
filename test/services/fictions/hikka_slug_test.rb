# frozen_string_literal: true

require 'test_helper'

module Fictions
  class HikkaSlugTest < ActiveSupport::TestCase
    test 'blank input becomes nil' do
      assert_nil HikkaSlug.normalize(nil)
      assert_nil HikkaSlug.normalize('   ')
    end

    test 'a bare slug is kept and lowercased' do
      assert_equal 'guimi-zhi-zhu-7059fd', HikkaSlug.normalize('  guimi-zhi-zhu-7059fd  ')
      assert_equal 'guimi-zhi-zhu', HikkaSlug.normalize('Guimi-ZHI-Zhu')
    end

    test 'a novel link yields its slug' do
      assert_equal 'guimi-zhi-zhu-7059fd', HikkaSlug.normalize('https://hikka.io/novel/guimi-zhi-zhu-7059fd')
      assert_equal 'abc', HikkaSlug.normalize('http://www.hikka.io/novel/abc/')
      assert_equal 'abc', HikkaSlug.normalize('https://hikka.io/novel/abc?ref=1#top')
    end

    test 'a link to another section is left for format validation to reject' do
      assert_equal 'https://hikka.io/manga/abc', HikkaSlug.normalize('https://hikka.io/manga/abc')
    end

    test 'text that is not a slug is left for format validation to reject' do
      assert_equal 'hello world', HikkaSlug.normalize('Hello World')
      assert_match HikkaSlug::FORMAT, 'abc-1'
      assert_no_match HikkaSlug::FORMAT, 'hello world'
    end
  end
end
