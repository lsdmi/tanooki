# frozen_string_literal: true

class SearchService
  def self.publications(query)
    Publication.joins(:rich_text_description, { publication_tags: :tag })
               .where('title LIKE :search OR tags.name LIKE :search OR body LIKE :search', search: "%#{query.join}%")
               .includes({ cover_attachment: :blob })
               .distinct
               .order(created_at: :desc)
  end

  def self.fictions(query)
    Fiction.where('title LIKE :search OR alternative_title LIKE :search OR english_title LIKE :search',
                  search: "%#{query.join}%")
           .includes([{ cover_attachment: :blob }, :chapters, :genres]).distinct
  end

  def self.videos(query)
    YoutubeVideo.joins(:rich_text_description)
                .where(
                  'youtube_videos.title LIKE :search OR tags LIKE :search OR body LIKE :search',
                  search: "%#{query.join}%"
                )
                .includes(:rich_text_description, :youtube_channel)
                .distinct
                .order(created_at: :desc)
  end
end
