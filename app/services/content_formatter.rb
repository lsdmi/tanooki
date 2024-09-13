# frozen_string_literal: true

class ContentFormatter
  class << self
    def html(chapter)
      <<-CONTENT
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
          <title>#{title(chapter)}</title>
          <style>
            #{css}
          </style>
        </head>
        <body class="epub-content">
          <h1 class="chapter-title">#{title(chapter)}</h1>
          #{format_content(chapter.content.body.to_s)}
        </body>
        </html>
      CONTENT
    end

    def title(chapter)
      chapter.title.presence || chapter.display_title
    end

    private

    def css
      @css ||= File.read(Rails.root.join('app', 'assets', 'stylesheets', 'epub_content.css'))
    end

    def format_content(content)
      content.gsub(/<\/br>/i, '')
             .gsub(/<br\s*>/i, '<br></br>')
             .gsub(/<img(.*?)>/, '<img\1></img>')
    end
  end
end
