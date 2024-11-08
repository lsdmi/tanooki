class Api::V1::FictionsController < ApplicationController
  def index
    @fictions = Rails.cache.fetch("fictions_hikka", expires_in: 1.hour) do
      Fiction.with_attached_cover.map do |fiction|
        fiction_to_json(fiction)
      end
    end
    render json: @fictions
  end

  private

  def fiction_to_json(fiction)
    {
      alternative_title: fiction.alternative_title,
      cover_url: url_for(fiction.cover),
      description: fiction.description,
      english_title: fiction.english_title,
      reference: fiction_url(fiction),
      title: fiction.title
    }
  end
end
