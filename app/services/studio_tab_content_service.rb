# frozen_string_literal: true

class StudioTabContentService
  include Pagy::Backend

  def initialize(user, active_tab, params = {})
    @user = user
    @active_tab = active_tab
    @params = params
  end

  def call
    send("#{@active_tab}_content_loader")
  end

  private

  attr_reader :user, :active_tab, :params

  def blogs_content_loader
    @pagy, @publications = pagy(user.publications.order(created_at: :desc), limit: 8)
  end

  def pokemons_content_loader
    @pokemon_show = PokemonShow.new(user)
  end

  def teams_content_loader
    @scanlators = user.admin? ? Scanlator.order(:title) : user.scanlators.order(:title)
  end

  def writings_content_loader
    @pagy, @fictions = pagy(fiction_list, limit: 8)
  end

  def notifications_content_loader
    @pagy, @comments = pagy(my_comments, limit: 8)
    user.update(latest_read_comment_id: latest_comments.first&.id)
  end

  def profile_content_loader
    @avatars = fetch_avatars
  end

  def fiction_list
    user.admin? ? fiction_all_ordered_by_latest_chapter : dashboard_fiction_list
  end

  def fetch_avatars
    Rails.cache.fetch('avatars', expires_in: 1.day) do
      Avatar.includes(:image_attachment).order(created_at: :desc)
    end
  end

  def my_comments
    Comment.where(id: latest_comments.pluck(:id)).order(id: :desc)
  end

  def latest_comments
    Rails.cache.fetch("latest_comments_for_#{user.id}", expires_in: 10.minutes) do
      CommentsFetcher.new(user).collect
    end
  end

  # Include FictionQuery methods
  def fiction_all_ordered_by_latest_chapter
    Fiction.includes(:cover_attachment, :genres).order(updated_at: :desc)
  end

  def dashboard_fiction_list
    user.fictions.includes(:cover_attachment, :genres).order(updated_at: :desc)
  end
end
