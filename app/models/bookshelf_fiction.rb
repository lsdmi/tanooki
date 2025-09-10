# frozen_string_literal: true

class BookshelfFiction < ApplicationRecord
  belongs_to :bookshelf
  belongs_to :fiction
end
