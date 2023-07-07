# frozen_string_literal: true

class ReadingProgress < ApplicationRecord
  belongs_to :chapter
  belongs_to :fiction
  belongs_to :user
end
