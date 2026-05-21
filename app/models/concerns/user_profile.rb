# frozen_string_literal: true

# Profile page data loaders for {User}.
module UserProfile
  extend ActiveSupport::Concern

  def profile_show_assignments
    {
      recent_publications: profile_recent_publications,
      user_scanlators: scanlators,
      recent_comments: profile_recent_comments,
      recent_readings: profile_recent_readings,
      user_bookshelves: profile_featured_bookshelves
    }
  end

  def profile_recent_publications
    publications.includes(:cover_attachment, :rich_text_description).weekly.recent.limit(3)
  end

  def profile_recent_comments
    comments.order(created_at: :desc).includes(:commentable).limit(3)
  end

  def profile_recent_readings
    readings.includes(fiction: :cover_attachment, chapter: {}).order(updated_at: :desc).limit(4)
  end

  def profile_featured_bookshelves
    bookshelves.includes(fictions: [:cover_attachment]).most_viewed.limit(1)
  end

  def profile_pokemon_stats
    {
      pokemon_count: pokemons.count,
      total_pokemon: Pokemon.where(descendant_level: 0).count,
      victories: battle_victory_count,
      total_battles: battle_total_count,
      user_rating: dex_leader_rank
    }
  end

  def battle_victory_count
    attacker_battle_logs.where(winner: self).count +
      defender_battle_logs.where(winner: self).count
  end

  def battle_total_count
    attacker_battle_logs.count + defender_battle_logs.count
  end

  def dex_leader_rank
    self.class.dex_leaders.index(self) + 1
  end
end
