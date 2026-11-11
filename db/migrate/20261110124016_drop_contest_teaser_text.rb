# frozen_string_literal: true

# Hub teaser line removed with the public /contests index.
class DropContestTeaserText < ActiveRecord::Migration[8.1]
  def change
    remove_column :contests, :teaser_text, :string, limit: 160
  end
end
