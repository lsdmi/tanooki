# frozen_string_literal: true

module Bookshelves
  # Hub age badge: max content_rating among visible shelf memberships.
  class HubMaxRatings
    def self.call(memberships)
      new(memberships).call
    end

    def initialize(memberships)
      @memberships = memberships
    end

    def call
      return {} if @memberships.none?

      @memberships.joins(:fiction)
                  .group(:bookshelf_id)
                  .maximum('fictions.content_rating')
    end
  end
end
