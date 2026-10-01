# frozen_string_literal: true

# Plain-text start of the description, so tale lists never load the full rich text body (often 100 KB+).
class AddExcerptToPublications < ActiveRecord::Migration[8.1]
  def up
    add_column :publications, :excerpt, :string, limit: Publication::EXCERPT_LENGTH, null: true, after: :title

    say_with_time 'Backfilling publication excerpts' do
      Publication.reset_column_information
      Publication.unscoped.includes(:rich_text_description).find_each(batch_size: 50) do |publication|
        publication.update_column(:excerpt, Publication.excerpt_from(publication.description))
      end
    end
  end

  def down
    remove_column :publications, :excerpt
  end
end
