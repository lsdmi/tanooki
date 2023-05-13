# frozen_string_literal: true

module CommentsHelper
  def fictions?
    @commentable.instance_of?(Fiction) || @commentable.instance_of?(Chapter)
  end
end
