# frozen_string_literal: true

# Join model linking fictions to genres.
class FictionGenre < ApplicationRecord
  belongs_to :fiction
  belongs_to :genre
end
