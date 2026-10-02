# frozen_string_literal: true

# Lazy chapter list sections load one fiction's volume, or a number range outside volumes.
class AddSectionIndexToChapters < ActiveRecord::Migration[8.1]
  def change
    add_index :chapters, %i[fiction_id volume_number number], name: 'index_chapters_on_fiction_volume_number'
  end
end
