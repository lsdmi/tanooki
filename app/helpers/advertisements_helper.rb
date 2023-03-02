# frozen_string_literal: true

module AdvertisementsHelper
  def formatted_description(description)
    sanitize(description.body.to_s, tags: %w[p a img strong em])
  end
end
