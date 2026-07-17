# frozen_string_literal: true

module Studio
  # Loads instance variables for the active Studio tab (blogs, pokemons, teams, etc.).
  class TabContent
    include Pagy::Backend

    ASSIGNMENT_KEYS = %i[
      pagy publications pokemon_show scanlators fictions comments avatars bookshelves epub_export_requests
      cover_quality_flags
    ].freeze

    def initialize(user, active_tab, params = {})
      @user = user
      @active_tab = TabCatalog.normalize_tab_id(active_tab)
      @params = params
    end

    def call
      send("#{@active_tab}_content_loader")
    end

    def to_controller_assignments
      ASSIGNMENT_KEYS.index_with { |key| instance_variable_get(:"@#{key}") }
    end

    private

    attr_reader :user, :active_tab, :params

    def blogs_content_loader
      @pagy, @publications = pagy(user.publications.includes(:rich_text_description).order(created_at: :desc), limit: 8)
    end

    def pokemons_content_loader
      @pokemon_show = Pokemons::StudioTab.new(user)
    end

    def teams_content_loader
      @pagy, @scanlators = pagy(
        scanlators_scope,
        limit: 8,
        page: params[:page]
      )
    end

    def scanlators_scope
      if user.admin?
        Scanlator.includes(:avatar_attachment).order(:title)
      else
        user.scanlators.includes(:avatar_attachment).order(:title)
      end
    end

    def writings_content_loader
      @pagy, @fictions = pagy(fiction_list.includes(cover_attachment: :blob), limit: 8)
      @cover_quality_flags = Fictions::CoverQualityFlags.for_fictions(@fictions)
    end

    def notifications_content_loader
      @pagy, @comments = pagy(my_comments, limit: 8)
      user.update(latest_read_comment_id: latest_comments.first&.id)
    end

    def profile_content_loader
      @avatars = fetch_avatars
    end

    def bookshelves_content_loader
      @bookshelves = user.bookshelves.ordered
    end

    def epub_exports_content_loader
      EpubExportRequest.sync_processing_for(user)
      @epub_export_requests = user.epub_export_requests.with_attached_file.order(created_at: :desc).limit(50)
    end

    def fiction_list
      user.admin? ? fiction_all : dashboard_fiction_list
    end

    def fetch_avatars
      Rails.cache.fetch('avatars', expires_in: 1.day) do
        Avatar.includes(:image_attachment).order(created_at: :desc)
      end
    end

    def my_comments
      Comment.where(id: latest_comments.pluck(:id)).includes({ user: { avatar: [:image_attachment] } },
                                                             :commentable).order(id: :desc)
    end

    def latest_comments
      Rails.cache.fetch("latest_comments_for_#{user.id}", expires_in: 10.minutes) do
        Comments::InboxCollector.new(user).call
      end
    end

    def fiction_all
      Fiction.order(:title)
    end

    def dashboard_fiction_list
      user.fictions.distinct.order(:title)
    end
  end
end
