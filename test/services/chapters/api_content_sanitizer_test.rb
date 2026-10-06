# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ApiContentSanitizerTest < ActiveSupport::TestCase
    def clean(html)
      ApiContentSanitizer.call(html)
    end

    test 'allowed formatting passes through unchanged' do
      html = '<h2>Розділ</h2><p><strong>Ж</strong> <em>К</em> <s>З</s> <u>П</u><br>рядок</p><blockquote><p>Ц</p>' \
             '</blockquote><hr><ul><li>один</li></ul><table><thead><tr><th>a</th></tr></thead><tbody><tr><td>1</td>' \
             '</tr></tbody></table>'
      result = clean(html)

      assert_equal html, result.html
      assert_empty result.changes
    end

    test 'scripts, styles and frames are removed with their content' do
      result = clean('<p>Текст</p><script>alert(1)</script><style>p{}</style><iframe src="https://x.test"></iframe>')

      assert_equal '<p>Текст</p>', result.html
      assert_equal ['тег <script>', 'тег <style>', 'тег <iframe>'], result.changes
    end

    test 'unknown tags are unwrapped and keep their text' do
      assert_equal '<p>Абзац у div і font</p>', clean('<div><p>Абзац у <font>div</font> і font</p></div>').html.squish
    end

    test 'style and event handler attributes are removed' do
      result = clean('<p style="color:red" onclick="x()" class="big">Текст</p><img src="/x" onerror="alert(1)">')

      assert_equal '<p>Текст</p>', result.html
      assert_includes result.changes, 'атрибут style'
      assert_includes result.changes, 'атрибут onclick'
    end

    test 'links keep http and https, other schemes lose the link but keep the text' do
      result = clean('<a href="https://ok.test" target="_blank">так</a> <a href="javascript:alert(1)">ні</a> ' \
                     '<a href=" JAVASCRIPT:x">ні</a> <a href="data:text/html,x">ні</a> <a href="mailto:a@b.c">ні</a>')

      assert_equal '<a href="https://ok.test">так</a> ні ні ні ні', result.html
      assert_includes result.changes, 'небезпечне посилання: javascript:alert(1)'
    end

    test 'images must come from chapter image storage' do
      stored = '/rails/active_storage/blobs/redirect/abc123--def/image.webp'
      foreign = '<img src="https://evil.test/x.png"><img src="data:image/png;base64,AAAA">'
      result = clean(%(<img src="#{stored}" alt="арт">#{foreign}))

      assert_equal %(<img src="#{stored}" alt="арт">), result.html
      assert_equal ['зображення з іншого сайту: https://evil.test/x.png',
                    'зображення з іншого сайту: вбудоване (base64)'], result.changes
    end

    test 'images on the CDN host are kept' do
      Images.stub(:cdn_host, 'https://cdn.baka.test') do
        assert_equal '<img src="https://cdn.baka.test/abc123">', clean('<img src="https://cdn.baka.test/abc123">').html
      end
    end

    test 'only composer note spans survive, with nothing but their note attributes' do
      note = '<span class="note-reference" data-note="Пояснення" data-note-id="note-1">слово</span>'
      noisy_note = note.sub('class="note-reference"', 'class="note-reference extra" style="color:red"')
      html = "#{noisy_note} <span class=\"big\">звичайний</span> <span class=\"note-reference\">без примітки</span>"

      assert_equal "#{note} звичайний без примітки", clean(html).html
    end

    test 'headings outside h2 to h4 and old strikethrough tags are renamed' do
      assert_equal '<h2>1</h2><h4>5</h4><h4>6</h4><s>a</s><s>b</s>',
                   clean('<h1>1</h1><h5>5</h5><h6>6</h6><del>a</del><strike>b</strike>').html
    end

    test 'comments and non-breaking spaces' do
      assert_equal '<p>а б в</p>', clean("<!-- коментар --><p>а&nbsp;б\u00A0в</p>").html
    end
  end
end
