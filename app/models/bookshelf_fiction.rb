# frozen_string_literal: true

# Join model linking bookshelves to fictions.
class BookshelfFiction < ApplicationRecord
  belongs_to :bookshelf
  belongs_to :fiction
end
