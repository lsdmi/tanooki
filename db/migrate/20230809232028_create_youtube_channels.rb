class CreateYoutubeChannels < ActiveRecord::Migration[7.0]
  def change
    create_table :youtube_channels do |t|
      t.string :channel_id, null: false
      t.string :title, null: false
      t.string :thumbnail, null: false

      t.timestamps
    end

    create_table :youtube_videos do |t|
      t.string :slug, null: false

      t.references :youtube_channel, foreign_key: true, null: false

      t.string :video_id, null: false
      t.string :title, null: false
      t.string :thumbnail, null: false
      t.string :tags

      t.integer :comments_count, default: 0
      t.integer :views, default: 0

      t.datetime :published_at, null: false
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
