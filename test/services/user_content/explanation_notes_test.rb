# frozen_string_literal: true

require 'test_helper'

module UserContent
  class ExplanationNotesTest < ActiveSupport::TestCase
    test 'every text color becomes the explanation class and the color is removed' do
      html = '<p>Текст <span style="color:#95a5a6;"><em>(1) примітка</em></span> далі</p>' \
             '<p style="color: red">Червоний</p>' \
             '<p style="color:blue;">Синій</p>'

      assert_equal '<p>Текст <span class="explanation"><em>(1) примітка</em></span> далі</p>' \
                   '<p class="explanation">Червоний</p>' \
                   '<p class="explanation">Синій</p>',
                   ExplanationNotes.call(html)
    end

    test 'keeps style properties that are not a text color' do
      html = '<p style="font-weight: 700; color: #95a5a6; text-align: center">Нотатка</p>'

      fragment = Nokogiri::HTML5.fragment(ExplanationNotes.call(html))
      paragraph = fragment.at_css('p')

      assert_includes paragraph['class'].split, 'explanation'
      assert_equal 'font-weight: 700; text-align: center', paragraph['style']
    end

    test 'does not treat border-color or background-color as a note' do
      html = '<p style="border-color: red; background-color: yellow">Край</p>'

      assert_equal html, ExplanationNotes.call(html)
    end

    test 'a bare italic footnote paragraph becomes a note' do
      html = '<p><em>(1) 咸鱼干: сушена риба.</em></p><p>Звичайний <em>наголос</em>.</p>'

      fragment = Nokogiri::HTML5.fragment(ExplanationNotes.call(html))
      notes = fragment.css('em.explanation')

      assert_equal 1, notes.size
      assert_match(/\A\(1\)/, notes.first.text)
      assert_nil fragment.at_css('p:last-child em')['class']
    end

    test 'leaves html without colors or italics unchanged' do
      html = '<p>Демонів- солдатів, які намагалися</p>'

      assert_equal html, ExplanationNotes.call(html)
    end

    test 'is idempotent once the class is present' do
      html = '<p class="explanation">Вже примітка</p>'

      assert_equal html, ExplanationNotes.call(html)
    end

    test 'html_for runs the Action Text sanitizer on a blog post' do
      publication = publications(:tale_approved_one)
      publication.description = '<div class="mx-auto max-w-3xl"><p style="color: red">Текст</p></div>' \
                                '<script>alert(1)</script>'

      html = ExplanationNotes.html_for(publication.description)

      assert_predicate html, :html_safe?
      assert_not_includes html, '<script'
      assert_equal '<div><p class="explanation">Текст</p></div>alert(1)', html.strip
    end
  end
end
