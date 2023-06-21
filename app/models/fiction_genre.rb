# frozen_string_literal: true

class FictionGenre < ApplicationRecord
  belongs_to :fiction
  belongs_to :genre
end
