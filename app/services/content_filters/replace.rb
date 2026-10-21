# frozen_string_literal: true

module ContentFilters
  # Replaces an account's rating cap and hidden genres in one transaction.
  class Replace
    RATINGS = { nil => nil, '' => nil, '0' => 0, '16' => 16, 0 => 0, 16 => 16 }.freeze
    Result = Data.define(:error) do
      def success?
        error.nil?
      end
    end

    def self.call(user:, max_content_rating:, hidden_genre_ids:)
      new(user:, max_content_rating:, hidden_genre_ids:).call
    end

    def initialize(user:, max_content_rating:, hidden_genre_ids:)
      @user = user
      @max_content_rating = max_content_rating
      @hidden_genre_ids = hidden_genre_ids
    end

    def call
      error = validation_error
      return Result.new(error:) if error

      persist
      Result.new(error: nil)
    end

    private

    def validation_error
      return I18n.t('content_filters.errors.rating') unless RATINGS.key?(@max_content_rating)
      return I18n.t('content_filters.errors.cap') if genre_ids.size > UserHiddenGenre::MAX_PER_USER
      return I18n.t('content_filters.errors.genre') if genre_ids.size != hideable_ids.size

      nil
    end

    def persist
      @user.transaction do
        sync_rating
        @user.hidden_genres.delete_all
        genres = Genre.where(id: genre_ids).index_by(&:id)
        genre_ids.each { |genre_id| save_genre(genres.fetch(genre_id)) }
      end
    end

    def save_genre(genre)
      hidden = @user.hidden_genres.build(genre:)
      hidden.skip_cap = true
      hidden.save!
    end

    def sync_rating
      filter = @user.content_filter
      if rating.nil?
        filter&.destroy!
        return
      end

      filter ||= @user.build_content_filter
      filter.update!(max_content_rating: rating)
    end

    def rating
      RATINGS[@max_content_rating]
    end

    def genre_ids
      @genre_ids ||= Array(@hidden_genre_ids).filter_map { |id| Integer(id, exception: false) }.uniq
    end

    def hideable_ids
      Genre.where(id: genre_ids).where.not(name: Genre::RATING_LABELS).pluck(:id)
    end
  end
end
