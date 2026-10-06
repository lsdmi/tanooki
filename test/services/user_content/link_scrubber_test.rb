# frozen_string_literal: true

require 'test_helper'

module UserContent
  class LinkScrubberTest < ActiveSupport::TestCase
    test 'chapter text marks links to other sites as user-generated' do
      link = rendered_link('<p><a href="https://example.com/page" target="_blank">x</a></p>')

      assert_equal %w[ugc nofollow noopener noreferrer], link['rel'].split
      assert_equal '_blank', link['target']
    end

    test 'keeps rel values the author already set' do
      link = rendered_link('<a href="https://example.com" rel="noopener">x</a>')

      assert_equal %w[noopener ugc nofollow noreferrer], link['rel'].split
    end

    test 'leaves links to our own pages alone' do
      ['/fictions/one', 'https://baka.in.ua/fictions/one', 'https://BAKA.in.ua/', '#note-1'].each do |href|
        assert_nil rendered_link(%(<a href="#{href}">x</a>))['rel'], href
      end
    end

    test 'marks protocol-relative links to other sites' do
      assert_includes rendered_link('<a href="//example.com/x">x</a>')['rel'], 'ugc'
    end

    test 'drops links to other sites that readers cannot see' do
      [
        '<p>голову<a href="https://azfreegame.com/" target="_blank" rel="noopener"><br></a></p>',
        "<p>текст<a href=\"https://spam.example/\">\u00A0\u200B </a></p>",
        '<p><a href="https://spam.example/" hidden>текст</a></p>',
        '<p><a href="https://spam.example/" style="display: none">текст</a></p>'
      ].each do |html|
        rendered = rendered_html(html)

        assert_not_includes rendered, 'href=', html
        assert_match(/<br>|текст/, rendered, html)
      end
    end

    test 'keeps image links and empty links to our own pages' do
      assert_not_nil rendered_link('<a href="https://example.com/art"><img src="https://example.com/a.png"></a>')
      assert_not_nil rendered_link('<a href="#note-1"></a>')
    end

    test 'drops links hidden in Word conditional comments' do
      html = rendered_html('<p>текст<!--[if gte vml 1]><v:rect href="https://pubfuture.com/"></v:rect><![endif]--></p>')

      assert_not_includes html, 'pubfuture'
    end

    test 'still strips unsafe hrefs and tags outside the allowed list' do
      html = rendered_html('<a href="javascript:alert(1)">x</a><script>alert(1)</script><mark>kept</mark>')

      assert_not_includes html, 'javascript:'
      assert_not_includes html, '<script'
      assert_includes html, '<mark>kept</mark>'
    end

    test 'keeps a youtube embed for chapters and the blog' do
      [
        'https://www.youtube.com/embed/video1',
        'https://www.youtube.com/embed/dQw4w9WgXcQ?start=10&rel=0',
        'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ/',
        'https://WWW.YouTube.com/embed/dQw4w9WgXcQ'
      ].each do |src|
        html = %(<p>текст<iframe src="#{src}" allowfullscreen="allowfullscreen"></iframe></p>)
        frame = Nokogiri::HTML5.fragment(rendered_html(html)).at_css('iframe')

        assert_not_nil frame, src
        assert_match %r{\Ahttps://www\.youtube(?:-nocookie)?\.com/embed/}i, frame['src']
        assert_equal 'allowfullscreen', frame['allowfullscreen']
      end
    end

    test 'drops an iframe that is not a youtube embed, together with the tag' do
      [
        'http://www.youtube.com/embed/dQw4w9WgXcQ',
        'https://youtube.com/embed/dQw4w9WgXcQ',
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://player.vimeo.com/video/1',
        'https://evil.example/embed/dQw4w9WgXcQ',
        'javascript:alert(1)',
        'data:text/html,hi',
        '//www.youtube.com/embed/dQw4w9WgXcQ',
        ''
      ].each do |src|
        html = rendered_html(%(<p>перед<iframe src="#{src}"></iframe>після</p>))

        assert_not_includes html, '<iframe', src
        assert_includes html, 'перед', src
        assert_includes html, 'після', src
      end
    end

    test 'rejects a youtube embed that is not a plain https url' do
      [
        'https://user@www.youtube.com/embed/dQw4w9WgXcQ',
        'https://www.youtube.com:444/embed/dQw4w9WgXcQ',
        'https://www.youtube.com.evil.test/embed/dQw4w9WgXcQ',
        'https://www.youtube.com/embed/',
        'https://www.youtube.com/embed/ab c',
        'https://www.youtube.com/embed/abc"<script>'
      ].each do |src|
        assert_not UserContent::LinkScrubber.youtube_embed?(src), src
      end
    end

    private

    def rendered_html(content)
      chapter = chapters(:one)
      chapter.content = content
      chapter.content.to_s
    end

    def rendered_link(content)
      Nokogiri::HTML5.fragment(rendered_html(content)).at_css('a')
    end
  end
end
