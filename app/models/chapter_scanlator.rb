# frozen_string_literal: true

# Join model linking chapters to scanlator teams.
class ChapterScanlator < ApplicationRecord
  belongs_to :chapter
  belongs_to :scanlator
end
