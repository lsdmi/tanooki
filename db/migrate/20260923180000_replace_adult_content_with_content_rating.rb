# frozen_string_literal: true

# One ordinal audience rating. Existing 18+ rows become eighteen; everything else stays everyone.
class ReplaceAdultContentWithContentRating < ActiveRecord::Migration[8.1]
  def up
    add_column :fictions, :content_rating, :integer, null: false, default: 0, after: :origin
    execute 'UPDATE fictions SET content_rating = 18 WHERE adult_content = true'
    add_index :fictions, :content_rating
    remove_column :fictions, :adult_content
  end

  def down
    add_column :fictions, :adult_content, :boolean, null: false, default: false, after: :origin
    execute 'UPDATE fictions SET adult_content = true WHERE content_rating = 18'
    remove_index :fictions, :content_rating
    remove_column :fictions, :content_rating
  end
end
