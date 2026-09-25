# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ReaderBlocksTest < ActiveSupport::TestCase
    test 'tags text blocks with monotonic indices in document order' do
      blocks = tagged('<h2>Розділ 1</h2><p>one</p><blockquote><p>two</p><p>three</p></blockquote>' \
                      '<ul><li>four</li></ul>')

      assert_equal %w[0 1 2 3 4], indices(blocks)
      assert_equal ['Розділ 1', 'one', 'two', 'three', 'four'], blocks.map(&:text)
    end

    test 'walks into nested containers instead of tagging them' do
      blocks = tagged('<div class="MuiBox-root"><div><p>one</p><p>two</p></div></div>')

      assert_equal %w[p p], blocks.map(&:name)
    end

    test 'splits a paragraph held together by line breaks into one span per line run' do
      html = ReaderBlocks.new('<p><span>first</span> line<br><br>second<br><br><br>third<br></p>').html
      blocks = Nokogiri::HTML5.fragment(html).css('[data-rp-i]')

      assert_equal %w[span span span], blocks.map(&:name)
      assert_equal ['first line', 'second', 'third'], blocks.map(&:text)
      assert_equal 6, Nokogiri::HTML5.fragment(html).css('br').size
    end

    test 'tags the paragraph itself when a line break leaves only one run' do
      blocks = tagged('<p>only<br></p>')

      assert_equal ['p'], blocks.map(&:name)
    end

    test 'skips blocks with no visible content but keeps images' do
      blocks = tagged('<p>one</p><p> </p><p><br></p><hr><figure><img src="/a.png"></figure><p>two</p>')

      assert_equal %w[p figure p], blocks.map(&:name)
      assert_equal %w[0 1 2], indices(blocks)
    end

    test 'digest is stable for the same content' do
      html = '<p>one</p><p>two</p>'

      assert_equal ReaderBlocks.new(html).digest, ReaderBlocks.new(html).digest
      assert_equal ReaderBlocks::DIGEST_LENGTH, ReaderBlocks.new(html).digest.length
    end

    test 'digest changes when text changes or blocks shift' do
      digest = ReaderBlocks.new('<p>one</p><p>two</p>').digest

      assert_not_equal digest, ReaderBlocks.new('<p>one</p><p>two!</p>').digest
      assert_not_equal digest, ReaderBlocks.new('<p>one two</p>').digest
      assert_not_equal digest, ReaderBlocks.new('<p>one</p><p><img src="/a.png"></p><p>two</p>').digest
    end

    test 'digest ignores markup that does not move blocks' do
      assert_equal ReaderBlocks.new('<p>one</p><p>two</p>').digest,
                   ReaderBlocks.new('<p><strong>one</strong></p><p class="MsoNormal">two</p>').digest
    end

    private

    def tagged(html)
      Nokogiri::HTML5.fragment(ReaderBlocks.new(html).html).css('[data-rp-i]')
    end

    def indices(blocks)
      blocks.pluck('data-rp-i')
    end
  end
end
