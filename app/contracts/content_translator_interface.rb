# frozen_string_literal: true

# Interface for content translation services
# This follows the Dependency Inversion Principle
module ContentTranslatorInterface
  def translate(article_text, title, tags)
    raise NotImplementedError, "#{self.class} must implement #translate"
  end
end
