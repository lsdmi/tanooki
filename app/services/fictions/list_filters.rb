# frozen_string_literal: true

module Fictions
  # Permits and normalizes fiction catalog URL filters for queries and Pagy links.
  class ListFilters
    KEYS = %i[genre tags only_new longreads evening top_rated finished licensed include_eighteen].freeze
    # `genre` is one id and `tags` a list of slugs; every other key is a flag written as `1`.
    FLAG_KEYS = (KEYS - %i[genre tags]).freeze
    # Read for one release after the rename; never written into query/pagy hashes.
    LEGACY_INCLUDE_EIGHTEEN_KEY = :adult_content
    PERMIT_KEYS = (KEYS - %i[tags] + [LEGACY_INCLUDE_EIGHTEEN_KEY, :page]).freeze
    MAX_TAGS = 5
    # FictionTags::Normalizer.slug output: lowercase latin words joined by single hyphens.
    TAG_SLUG = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

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
      @permitted = controller_params.permit(*PERMIT_KEYS, tags: [])
    end

    def include_eighteen_param_specified?
      param_key?(:include_eighteen) || param_key?(LEGACY_INCLUDE_EIGHTEEN_KEY)
    end

    def include_eighteen?
      truthy?(normalized[:include_eighteen])
    end

    def to_query_hash
      query = normalized.slice(*KEYS).except(:tags).to_h
      query[:tags] = tag_slugs if tag_slugs.any?
      query
    end

    def to_pagy_hash
      {}.tap do |h|
        genre = normalized[:genre].to_s
        h[:genre] = genre if genre.match?(/\A\d+\z/)
        h[:tags] = tag_slugs if tag_slugs.any?

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

    def tag_slugs
      @tag_slugs ||= Array(normalized[:tags]).filter_map { |slug| slug.to_s.strip.downcase.presence }
                                             .grep(TAG_SLUG)
                                             .uniq
                                             .first(MAX_TAGS)
    end

    def param_key?(key)
      @permitted.key?(key) || @permitted.key?(key.to_s)
    end

    def truthy?(value)
      ActiveModel::Type::Boolean.new.cast(value) == true
    end
  end
end
