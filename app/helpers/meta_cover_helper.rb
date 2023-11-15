# frozen_string_literal: true

module MetaCoverHelper
  def meta_cover
    if cover_object.present?
      object_cover(cover_object)
    elsif @youtube_video&.persisted?
      @youtube_video.thumbnail
    elsif @scanlator&.persisted?
      scanlator_avatar
    end
  end

  private

  def cover_object
    @cover_object ||= [@publication, @fiction, @chapter&.fiction].compact.find(&:persisted?)
  end

  def object_cover(item)
    item&.cover
  end

  def scanlator_avatar
    @scanlator&.avatar.presence || url_for(asset_path('scanlator_avatar.webp'))
  end
end
