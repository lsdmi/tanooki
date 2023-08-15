# frozen_string_literal: true

module YoutubeVideosHelper
  def split_tags(video)
    video.tags.split(', ')
  end
end
