# frozen_string_literal: true

module Fictions
  # Permits and normalizes fiction catalog URL filters for queries and Pagy links.
  class ListFilters
    KEYS = %i[genre only_new longreads evening top_rated finished include_eighteen].freeze
    FLAG_KEYS = (KEYS - [:genre]).freeze
    # Read for one release after the rename; never written into query/pagy hashes.
    LEGACY_INCLUDE_EIGHTEEN_KEY = :adult_content
    PERMIT_KEYS = (KEYS + [LEGACY_INCLUDE_EIGHTEEN_KEY, :page]).freeze

    class << self
      def permit_for_query(controller_params)
        new(controller_params).to_query_hash
      end

      def permit_for_pagy(controller_params)
        new(controller_params).to_pagy_hash
      end

      def include_eighteen?(controller_params)
        new(controller_params).include_eighteen?
      end

      def include_eighteen_param_specified?(controller_params)
        new(controller_params).include_eighteen_param_specified?
      end
    end

    def initialize(controller_params)
      @permitted = controller_params.permit(*PERMIT_KEYS)
    end

    def include_eighteen_param_specified?
      param_key?(:include_eighteen) || param_key?(LEGACY_INCLUDE_EIGHTEEN_KEY)
    end

    def include_eighteen?
      truthy?(normalized[:include_eighteen])
    end

    def to_query_hash
      normalized.slice(*KEYS).to_h
    end

    def to_pagy_hash
      {}.tap do |h|
        genre = normalized[:genre].to_s
        h[:genre] = genre if genre.match?(/\A\d+\z/)

        FLAG_KEYS.each do |key|
          h[key] = '1' if truthy?(normalized[key])
        end
      end
    end

    private

    def normalized
      @normalized ||= begin
        attrs = @permitted.to_h.symbolize_keys
        if attrs[:include_eighteen].nil? && !attrs[LEGACY_INCLUDE_EIGHTEEN_KEY].nil?
          attrs[:include_eighteen] = attrs[LEGACY_INCLUDE_EIGHTEEN_KEY]
        end
        attrs.except(LEGACY_INCLUDE_EIGHTEEN_KEY)
      end
    end

    def param_key?(key)
      @permitted.key?(key) || @permitted.key?(key.to_s)
    end

    def truthy?(value)
      ActiveModel::Type::Boolean.new.cast(value) == true
    end
  end
end
