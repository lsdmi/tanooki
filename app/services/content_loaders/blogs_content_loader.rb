# frozen_string_literal: true

class BlogsContentLoader < BaseContentLoader
  def call
    service.instance_variable_set(:@pagy, pagy)
    service.instance_variable_set(:@publications, publications)
  end

  private

  def pagy
    @pagy ||= Pagy.new(user.publications.order(created_at: :desc), limit: 8)
  end

  def publications
    @publications ||= user.publications.order(created_at: :desc).limit(8)
  end
end
