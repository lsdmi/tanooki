# frozen_string_literal: true

class CoverGenerator
  def self.generate(chapter)
    new(chapter).generate
  end

  def initialize(chapter)
    @chapter = chapter
  end

  def generate
    render_html
  end

  private

  attr_reader :chapter

  def render_html
    <<-HTML
      <!DOCTYPE html>
      <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>#{chapter.title}</title>
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

  def cover_styles
    @cover_styles ||= File.read(Rails.root.join('app', 'assets', 'stylesheets', 'epub_cover.css'))
  end

  def cover_content
    CoverContentBuilder.new(chapter).build
  end
end
