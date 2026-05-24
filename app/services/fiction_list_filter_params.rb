# frozen_string_literal: true

# Strong filtering for fiction-list URLs (pagination + FictionListQueryBuilder).
class FictionListFilterParams
  KEYS = %i[genre only_new longreads evening top_rated finished adult_content].freeze
  FLAG_KEYS = (KEYS - [:genre]).freeze
  PERMIT_KEYS = (KEYS + [:page]).freeze

  class << self
    def permit_for_query(controller_params)
      new(controller_params).to_query_hash
    end

    def permit_for_pagy(controller_params)
      new(controller_params).to_pagy_hash
    end
  end

  def initialize(controller_params)
    @permitted = controller_params.permit(*PERMIT_KEYS)
  end

  def to_query_hash
    @permitted.slice(*KEYS).to_h
  end

  def to_pagy_hash
    {}.tap do |h|
      genre = @permitted[:genre].to_s
      h[:genre] = genre if genre.match?(/\A\d+\z/)

      FLAG_KEYS.each do |key|
        h[key] = '1' if @permitted[key].present?
      end
    end
  end
end
