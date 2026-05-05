# frozen_string_literal: true

# Ranking + card payloads for «Популярне ранобе» on genre pages.
module FictionGenrePageNewReleases
  extend ActiveSupport::Concern

  FEATURED_CARD_ACCENTS = [
    'from-slate-800 to-slate-950',
    'from-indigo-950 via-slate-900 to-slate-950'
  ].freeze

  # Locals for compact genre cards (thumbs / «Нові Релізи» grid).
  def genre_thumb_card_locals(fiction, released_n:, accent_index:)
    label = chapters_label_for_card(released_n, fiction)
    shared_card_fields(fiction, label).merge(fiction: fiction, title: fiction.title,
                                             accent: card_accent_at(accent_index))
  end

  private

  def top_eight_most_read_in_genre
    @top_eight_most_read_in_genre ||= Fictions::Ranker.most_read_fictions_for_genre(genre, limit: 8)
  end

  def new_releases_ranked_cards
    @new_releases_ranked_cards ||= build_new_releases_ranked_cards
  end

  def build_new_releases_ranked_cards
    fictions = top_eight_most_read_in_genre
    return [] if fictions.empty?

    ActiveRecord::Associations::Preloader.new(records: fictions, associations: [:genres]).call

    released_counts =
      Chapter.where(fiction_id: fictions.map(&:id)).merge(Chapter.released).group(:fiction_id).count

    fictions.each_with_index.map { |fiction, index| new_release_ranked_row(fiction, index, released_counts) }
  end

  def new_release_ranked_row(fiction, index, released_by_fiction)
    n = released_by_fiction[fiction.id].to_i
    shared_card_fields(fiction, chapters_label_for_card(n, fiction)).merge(ranked_extras(fiction, index))
  end

  def ranked_extras(fiction, index)
    {
      fiction: fiction,
      rank: index + 1,
      title: fiction.title,
      author: fiction.author,
      excerpt: featured_excerpt_for(fiction),
      genres: genre_links_for_card(fiction),
      accent: card_accent_at(index)
    }
  end

  def chapters_label_for_card(released_n, fiction)
    released_n.positive? ? released_n.to_s : fiction.total_chapters.to_s
  end

  def shared_card_fields(fiction, chapters_label)
    {
      rating: formatted_avg_rating(fiction),
      chapters: chapters_label,
      views: helpers.format_view_count(fiction.views),
      status: fiction_status_label(fiction)
    }
  end

  def genre_links_for_card(fiction)
    fiction.genres.order(:name).limit(4).map { |g| { name: g.name, slug: g.slug } }
  end

  def card_accent_at(index)
    FEATURED_CARD_ACCENTS[index % FEATURED_CARD_ACCENTS.size]
  end

  def formatted_avg_rating(fiction)
    return '—' unless fiction.average_rating.positive?

    helpers.number_with_precision(fiction.average_rating, precision: 1)
  end

  def fiction_status_label(fiction)
    (Fiction.statuses[fiction.status] || fiction.status).to_s
  end

  def featured_excerpt_for(fiction)
    raw = fiction.description.to_s
    helpers.truncate(helpers.strip_tags(raw), length: 280, separator: ' ')
  end
end
