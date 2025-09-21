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
    @pagy, @publications = pagy(user.publications.includes(:rich_text_description).order(created_at: :desc), limit: 8)
  end

  def pokemons_content_loader
    @pokemon_show = PokemonShow.new(user)
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
    @pagy, @fictions = pagy(fiction_list, limit: 8)
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
    CommentsFetcher.new(user).collect
  end

  def fiction_all
    Fiction.order(:title)
  end

  def dashboard_fiction_list
    user.fictions.distinct.order(:title)
  end
end
