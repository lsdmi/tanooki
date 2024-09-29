# frozen_string_literal: true

class CoverGenerator
  def self.generate(chapter, volume_title = nil)
    new(chapter, volume_title).generate
  end

  def initialize(chapter, volume_title = nil)
    @chapter = chapter
    @volume_title = volume_title
  end

  def generate
    render_html
  end

  private

  attr_reader :chapter, :volume_title

  def render_html
    <<-HTML
      <!DOCTYPE html>
      <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>#{title}</title>
        <style>
          #{cover_styles}
        </style>
      </head>
      <body class="epub-cover">
        <div class="container">
          #{cover_content}
        </div>
      </body>
      </html>
    HTML
  end

  def title
    volume_title || chapter.title
  end

  def cover_styles
    @cover_styles ||= File.read(Rails.root.join('app', 'assets', 'stylesheets', 'epub_cover.css'))
  end

  def cover_content
    CoverContentBuilder.new(chapter, volume_title:).build
  end
end
