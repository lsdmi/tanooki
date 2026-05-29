# frozen_string_literal: true

# Indexes for hot filters and sorts on library, fiction index, publications, and YouTube pages.
class AddHotQueryIndexes < ActiveRecord::Migration[8.0]
  def change
    add_reading_progress_indexes
    add_publication_indexes
    add_fiction_indexes
    add_youtube_video_indexes
  end

  private

  def add_reading_progress_indexes
    change_table :reading_progresses, bulk: true do |t|
      t.index %i[user_id updated_at], name: 'index_reading_progresses_on_user_id_and_updated_at'
      t.index %i[created_at fiction_id], name: 'index_reading_progresses_on_created_at_and_fiction_id'
    end
  end

  def add_publication_indexes
    change_table :publications, bulk: true do |t|
      t.index :created_at
      t.index :views
    end
  end

  def add_fiction_indexes
    change_table :fictions, bulk: true do |t|
      t.index :views
      t.index :status
      t.index :created_at
    end
  end

  def add_youtube_video_indexes
    change_table :youtube_videos, bulk: true do |t|
      t.index :published_at
      t.index :views
      t.index %i[youtube_channel_id published_at], name: 'index_youtube_videos_on_channel_id_and_published_at'
    end
  end
end
