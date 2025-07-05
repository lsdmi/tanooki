# frozen_string_literal: true

# Responsible for inserting videos into HTML content
class VideoInserter
  def insert_video(html, video_url, after_paragraph:)
    return html unless video_url

    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    target_p = doc.css('p')[after_paragraph]
    return html unless target_p

    iframe_html = %(<iframe src="#{video_url}" width="#{BlogScraperConfig.video_width}" ) +
                  %(height="#{BlogScraperConfig.video_height}" allowfullscreen></iframe>)
    target_p.add_next_sibling(iframe_html)
    target_p.next_sibling.add_next_sibling('<br>')
    doc.to_html
  end
end
