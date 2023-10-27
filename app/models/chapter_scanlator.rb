# frozen_string_literal: true

class ChapterScanlator < ApplicationRecord
  belongs_to :chapter
  belongs_to :scanlator
end
