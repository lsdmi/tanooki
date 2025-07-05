# frozen_string_literal: true

# Configuration class for BlogScraper
# This centralizes all configuration constants and makes the system more maintainable
class BlogScraperConfig
  # RSS Configuration
  RSS_URL = 'https://www.animenewsnetwork.com/all/rss.xml?ann-edition=us'

  # HTML Selectors
  ARTICLE_BODY_SELECTORS = ['div.meat', 'div.KonaBody'].freeze
  VIDEO_IFRAME_SELECTOR = 'iframe[title="YouTube video player"]'
  COVER_IMAGE_SELECTOR = 'link[rel="image_src"]'

  # Publication Configuration
  PUBLICATION_TYPE = 'Tale'
  HIGHLIGHT = true
  USER_ID = 1

  # Video Configuration
  VIDEO_INSERT_AFTER_PARAGRAPH = 2
  VIDEO_WIDTH = '100%'
  VIDEO_HEIGHT = '314'

  # OpenAI Configuration
  OPENAI_MODEL = 'gpt-4.1'
  OPENAI_TEMPERATURE = 0.5
  OPENAI_SYSTEM_PROMPT = 'Ти професійний український журналіст та HTML-форматувальник.'

  class << self
    def rss_url
      RSS_URL
    end

    def article_body_selectors
      ARTICLE_BODY_SELECTORS
    end

    def video_iframe_selector
      VIDEO_IFRAME_SELECTOR
    end

    def cover_image_selector
      COVER_IMAGE_SELECTOR
    end

    def publication_type
      PUBLICATION_TYPE
    end

    def highlight
      HIGHLIGHT
    end

    def user_id
      USER_ID
    end

    def video_insert_after_paragraph
      VIDEO_INSERT_AFTER_PARAGRAPH
    end

    def video_width
      VIDEO_WIDTH
    end

    def video_height
      VIDEO_HEIGHT
    end

    def openai_model
      OPENAI_MODEL
    end

    def openai_temperature
      OPENAI_TEMPERATURE
    end

    def openai_system_prompt
      OPENAI_SYSTEM_PROMPT
    end
  end
end
