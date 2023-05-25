# frozen_string_literal: true

module CommentsHelper
  def fictions?
    @commentable.instance_of?(Fiction) || @commentable.instance_of?(Chapter)
  end

  def application_record_child(object)
    object.class.superclass == ApplicationRecord ? object.class : object.class.superclass
  end
end
