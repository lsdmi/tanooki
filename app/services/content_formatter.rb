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
      chapter.display_title_no_volume || chapter.title.presence
    end

    private

    def css
      @css ||= File.read(Rails.root.join('app', 'assets', 'stylesheets', 'epub_content.css'))
    end

    def format_content(content)
      content.gsub(%r{</br>}i, '')
             .gsub(/<br\s*>/i, '<br></br>')
             .gsub(/<hr\s*>/i, '<hr></hr>')
             .gsub(/<img(.*?)>/, '<img\1></img>')
             .gsub(/&nbsp;/i, '&#160;')
    end
  end
end
