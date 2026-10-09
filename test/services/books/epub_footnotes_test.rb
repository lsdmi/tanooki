# frozen_string_literal: true

require 'test_helper'

module Books
  class EpubFootnotesTest < ActiveSupport::TestCase
    test 'the noted word becomes the popup link' do
      link = convert(noted('Меча', 'Одна з великих сект.')).at_css('a.noteref')

      assert_equal 'Меча', link.text
      assert_equal '#note-1', link['href']
      assert_equal 'noteref', link['epub:type']
    end

    test 'the note text becomes an aside after the chapter' do
      fragment = convert(noted('Меча', 'Одна з великих сект.'))
      aside = fragment.at_css('aside.footnote')

      assert_equal 'note-1', aside['id']
      assert_equal 'footnote', aside['epub:type']
      assert_equal aside, fragment.element_children.last
    end

    test 'the aside holds the note text and the tooltip span is gone' do
      fragment = convert(noted('Меча', 'Одна з великих сект.'))

      assert_equal 'Одна з великих сект.', fragment.at_css('aside.footnote p').text
      assert_equal 'doc-footnote', fragment.at_css('aside.footnote')['role']
      assert_nil fragment.at_css('span.note-reference, [data-note]')
    end

    test 'keeps markup inside the noted word' do
      html = '<p><span class="note-reference" data-note="Секта." data-note-id="note-1"><strong>Меча</strong></span></p>'

      assert_equal 'Меча', convert(html).at_css('a.noteref strong').text
    end

    test 'two notes stay in order and keep their own text' do
      html = '<p><span class="note-reference" data-note="Перша." data-note-id="note-1">А</span> ' \
             '<span class="note-reference" data-note="Друга." data-note-id="note-2">Б</span></p>'

      fragment = convert(html)

      assert_equal ['#note-1', '#note-2'], fragment.css('a.noteref').pluck('href')
      assert_equal ['Перша.', 'Друга.'], fragment.css('aside.footnote p').map(&:text)
    end

    test 'escapes note text' do
      html = '<p><span class="note-reference" data-note="A &amp; B &lt;i&gt;" data-note-id="note-1">Слово</span></p>'

      assert_equal 'A & B <i>', convert(html).at_css('aside p').text
    end

    test 'a note with no text is unwrapped' do
      html = '<p>До <span class="note-reference" data-note="  " data-note-id="note-1">слова</span>.</p>'

      assert_equal '<p>До слова.</p>', EpubFootnotes.call(html)
    end

    test 'a duplicate or invalid id is made unique and safe' do
      html = '<p id="note-1"><span class="note-reference" data-note="Перша." data-note-id="note-1">А</span></p>' \
             '<p><span class="note-reference" data-note="Друга." data-note-id="note-1">Б</span></p>' \
             '<p><span class="note-reference" data-note="Третя." data-note-id="1 bad">В</span></p>'

      fragment = convert(html)

      assert_equal ['#note-1-2', '#note-1-3', '#fn'], fragment.css('a.noteref').pluck('href')
      assert_equal %w[note-1-2 note-1-3 fn], fragment.css('aside.footnote').pluck('id')
    end

    test 'a note around a link gets a superscript marker instead of a nested anchor' do
      html = '<p>До <span class="note-reference" data-note="Секта." data-note-id="note-1">' \
             '<a href="https://example.com">Меча</a></span> кінець.</p>'

      fragment = convert(html)

      assert_equal 'https://example.com', fragment.at_css('a:not(.noteref)')['href']
      assert_equal '1', fragment.at_css('a.noteref sup').text
      assert_nil fragment.at_css('a a')
    end

    test 'a note inside a link gets the marker after that link' do
      html = '<p><a href="https://example.com">До <span class="note-reference" data-note="Секта." ' \
             'data-note-id="note-1">Меча</span></a> кінець.</p>'

      fragment = convert(html)
      paragraph = fragment.at_css('p')

      assert_includes paragraph.at_css('a:not(.noteref)').text, 'Меча'
      assert_equal paragraph.at_css('a:not(.noteref)').next_element, paragraph.at_css('a.noteref')
    end

    test 'leaves html without a note span untouched' do
      html = '<p>Згадка note-reference у тексті.</p>'

      assert_equal html, EpubFootnotes.call(html)
    end

    test 'a chapter export is well-formed xml and still normalizes the body' do
      body = "#{noted('Меча', 'Секта &amp; клан')}<p style=\"font-size: 24px\">Звичайний</p><hr>"
      html = EpubChapterBodies.stub(:raw_html, body) { EpubChapterHtml.html(chapters(:one)) }
      document = Nokogiri::XML(html)

      assert_empty document.errors
      assert_equal 'Секта & клан', document.at_css('aside.footnote p').text
      assert_includes html, '<hr />'
    end

    test 'a chapter export drops the tooltip and reader-owned styles' do
      body = "#{noted('Меча', 'Секта')}<p style=\"font-size: 24px\">Звичайний</p>"
      html = EpubChapterBodies.stub(:raw_html, body) { EpubChapterHtml.html(chapters(:one)) }

      assert_includes html, 'xmlns:epub="http://www.idpf.org/2007/ops"'
      assert_not_includes html, 'note-reference'
      assert_not_includes html, 'font-size: 24px'
    end

    private

    def noted(word, note)
      %(<p>Текст <span class="note-reference" data-note="#{note}" data-note-id="note-1">#{word}</span>.</p>)
    end

    def convert(html)
      Nokogiri::HTML5.fragment(EpubFootnotes.call(html))
    end
  end
end
