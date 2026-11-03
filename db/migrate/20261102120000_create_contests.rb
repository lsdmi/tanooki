# frozen_string_literal: true

# Contest entity, entries, prizes, jurors, and awards (CONTESTS.md P0 0.1).
class CreateContests < ActiveRecord::Migration[8.1]
  def change
    create_table :contests, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.string :slug, null: false
      t.string :title, null: false
      t.string :tagline, limit: 160
      t.string :kind, null: false, limit: 16, default: 'original'
      t.string :preset_key, limit: 32
      t.integer :preset_version
      t.references :source_contest, foreign_key: { to_table: :contests, on_delete: :nullify }
      t.string :teaser_text, limit: 160
      t.json :rules_snapshot
      t.json :rule_changes, null: false
      t.integer :carryover_uah, null: false, default: 0
      t.json :report
      t.datetime :report_generated_at
      t.datetime :announced_at, null: false
      t.datetime :submissions_open_at, null: false
      t.datetime :submissions_close_at, null: false
      t.datetime :judging_close_at, null: false
      t.datetime :published_at
      t.datetime :results_published_at
      t.datetime :cancelled_at
      t.string :cancel_reason
      t.references :required_genre, foreign_key: { to_table: :genres, on_delete: :nullify }
      t.boolean :requires_new_work, null: false, default: true
      t.integer :min_chapters
      t.integer :min_words
      t.integer :max_words
      t.integer :judged_word_cap
      t.string :judged_chapters_scope, null: false, limit: 16, default: 'until_close'
      t.boolean :requires_completed, null: false, default: false
      t.integer :max_content_rating, null: false, default: 18
      t.integer :max_entries_per_user, null: false, default: 1
      t.integer :jury_weight, null: false, default: 60
      t.json :criteria, null: false
      t.integer :prize_pool_uah, null: false, default: 0
      t.integer :donations_uah, null: false, default: 0
      t.string :donation_url
      t.json :sponsors, null: false
      t.json :announcements_sent, null: false
      t.integer :comments_count, null: false, default: 0
      t.timestamps

      t.index :slug, unique: true
      t.index :submissions_open_at
      t.index :results_published_at
    end

    create_table :contest_prizes, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :contest, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false, default: 0
      t.string :title, null: false
      t.string :kind, null: false, limit: 16, default: 'place'
      t.integer :place
      t.integer :cash_uah, null: false, default: 0
      t.integer :unlock_at_uah
      t.string :perks
      t.references :avatar, foreign_key: { on_delete: :nullify }
      t.timestamps

      t.index %i[contest_id position], name: 'index_contest_prizes_on_contest_and_position'
    end

    create_table :contest_entries, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :contest, null: false, foreign_key: { on_delete: :cascade }
      t.references :fiction, foreign_key: { on_delete: :cascade }
      t.references :submitter, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :scanlator, foreign_key: { on_delete: :nullify }
      t.string :legacy_title
      t.string :legacy_author
      t.string :legacy_url
      t.string :status, null: false, limit: 16, default: 'accepted'
      t.string :status_reason
      t.string :ai_usage, null: false, limit: 16, default: 'none'
      t.text :ai_note
      t.datetime :rules_accepted_at
      t.datetime :submitted_at, null: false
      t.datetime :reviewed_at
      t.references :reviewed_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.json :locked_snapshot
      t.json :reader_stats
      t.decimal :jury_score, precision: 5, scale: 2
      t.json :jury_breakdown
      t.text :jury_review
      t.text :jury_private_review
      t.decimal :reader_score, precision: 5, scale: 2
      t.decimal :final_score, precision: 5, scale: 2
      t.integer :final_rank
      t.timestamps

      t.index %i[contest_id fiction_id], unique: true, name: 'index_contest_entries_on_contest_and_fiction'
      t.index %i[contest_id status], name: 'index_contest_entries_on_contest_and_status'
    end

    create_table :contest_entry_authors, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :contest_entry, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps

      t.index %i[contest_entry_id user_id], unique: true, name: 'index_contest_entry_authors_on_entry_and_user'
    end

    create_table :contest_jurors, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :contest, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :role, null: false, limit: 16, default: 'member'
      t.string :public_bio
      t.timestamps

      t.index %i[contest_id user_id], unique: true, name: 'index_contest_jurors_on_contest_and_user'
    end

    create_table :contest_awards, charset: 'utf8mb4', collation: 'utf8mb4_0900_ai_ci' do |t|
      t.references :contest, null: false, foreign_key: { on_delete: :cascade }
      t.references :contest_prize, null: false, foreign_key: { on_delete: :cascade }
      t.references :contest_entry, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :awarded_at, null: false
      t.datetime :paid_at
      t.string :payout_note
      t.timestamps

      t.index %i[contest_id contest_prize_id], name: 'index_contest_awards_on_contest_and_prize'
    end

    change_table :avatars, bulk: true do |t|
      t.references :contest, foreign_key: { on_delete: :nullify }
    end
  end
end
