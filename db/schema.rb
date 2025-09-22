# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_22_114026) do
  create_table "action_text_rich_texts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.text "body", size: :long
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "advertisements", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "slug", null: false
    t.string "resource", null: false
    t.boolean "enabled", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_advertisements_on_enabled"
    t.index ["slug"], name: "index_advertisements_on_slug", unique: true
  end

  create_table "avatars", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "bookshelf_fictions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "bookshelf_id", null: false
    t.bigint "fiction_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bookshelf_id", "fiction_id"], name: "index_bookshelf_fictions_on_bookshelf_id_and_fiction_id", unique: true
    t.index ["bookshelf_id"], name: "index_bookshelf_fictions_on_bookshelf_id"
    t.index ["fiction_id"], name: "index_bookshelf_fictions_on_fiction_id"
  end

  create_table "bookshelves", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.bigint "user_id", null: false
    t.integer "views", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_bookshelves_on_user_id"
  end

  create_table "chapter_scanlators", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "chapter_id", null: false
    t.bigint "scanlator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chapter_id"], name: "index_chapter_scanlators_on_chapter_id"
    t.index ["scanlator_id"], name: "index_chapter_scanlators_on_scanlator_id"
  end

  create_table "chapters", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "slug", null: false
    t.bigint "fiction_id", null: false
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.decimal "number", precision: 9, scale: 2, null: false
    t.decimal "volume_number", precision: 9, scale: 1
    t.integer "comments_count", default: 0
    t.integer "views", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["fiction_id"], name: "index_chapters_on_fiction_id"
    t.index ["slug"], name: "index_chapters_on_slug", unique: true
    t.index ["user_id"], name: "index_chapters_on_user_id"
  end

  create_table "chat_messages", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "content", null: false
    t.string "room", default: "general", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_chat_messages_on_created_at"
    t.index ["room"], name: "index_chat_messages_on_room"
    t.index ["user_id"], name: "index_chat_messages_on_user_id"
  end

  create_table "comments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "parent_id"
    t.bigint "commentable_id", null: false
    t.string "commentable_type", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "fiction_genres", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "fiction_id"
    t.bigint "genre_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fiction_id"], name: "index_fiction_genres_on_fiction_id"
    t.index ["genre_id"], name: "index_fiction_genres_on_genre_id"
  end

  create_table "fiction_ratings", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "fiction_id", null: false
    t.integer "rating", limit: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fiction_id"], name: "index_fiction_ratings_on_fiction_id"
    t.index ["user_id", "fiction_id"], name: "index_fiction_ratings_on_user_and_fiction", unique: true
    t.index ["user_id"], name: "index_fiction_ratings_on_user_id"
    t.check_constraint "(`rating` >= 1) and (`rating` <= 5)", name: "check_rating_range"
  end

  create_table "fiction_scanlators", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "fiction_id", null: false
    t.bigint "scanlator_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fiction_id"], name: "index_fiction_scanlators_on_fiction_id"
    t.index ["scanlator_id"], name: "index_fiction_scanlators_on_scanlator_id"
  end

  create_table "fictions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "slug", null: false
    t.string "title", null: false
    t.string "alternative_title"
    t.string "english_title"
    t.text "description", null: false
    t.text "short_description"
    t.integer "comments_count", default: 0
    t.integer "views", default: 0
    t.string "status", null: false
    t.string "author", null: false
    t.string "origin"
    t.integer "total_chapters", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["slug"], name: "index_fictions_on_slug", unique: true
  end

  create_table "genres", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_genres_on_name"
  end

  create_table "pokemon_battle_logs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "attacker_id", null: false
    t.bigint "defender_id", null: false
    t.bigint "winner_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attacker_id"], name: "index_pokemon_battle_logs_on_attacker_id"
    t.index ["defender_id"], name: "index_pokemon_battle_logs_on_defender_id"
    t.index ["winner_id"], name: "index_pokemon_battle_logs_on_winner_id"
  end

  create_table "pokemon_type_relations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "pokemon_id", null: false
    t.bigint "pokemon_type_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pokemon_id", "pokemon_type_id"], name: "index_pokemon_type_relations_on_pokemon_id_and_pokemon_type_id", unique: true
    t.index ["pokemon_id"], name: "index_pokemon_type_relations_on_pokemon_id"
    t.index ["pokemon_type_id"], name: "index_pokemon_type_relations_on_pokemon_type_id"
  end

  create_table "pokemon_types", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pokemons", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "dex_id"
    t.string "slug", null: false
    t.string "name", null: false
    t.integer "power_level", null: false
    t.integer "rarity", null: false
    t.bigint "ancestor_id"
    t.bigint "descendant_id"
    t.integer "descendant_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ancestor_id"], name: "index_pokemons_on_ancestor_id"
    t.index ["descendant_id"], name: "index_pokemons_on_descendant_id"
    t.index ["name"], name: "index_pokemons_on_name"
  end

  create_table "publication_tags", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "publication_id"
    t.bigint "tag_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["publication_id"], name: "index_publication_tags_on_publication_id"
    t.index ["tag_id"], name: "index_publication_tags_on_tag_id"
  end

  create_table "publications", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "slug", null: false
    t.string "type", null: false
    t.string "title", null: false
    t.boolean "highlight", default: false
    t.bigint "user_id", null: false
    t.integer "comments_count", default: 0
    t.integer "views", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["slug"], name: "index_publications_on_slug", unique: true
    t.index ["user_id"], name: "index_publications_on_user_id"
  end

  create_table "reading_progresses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "fiction_id", null: false
    t.bigint "user_id", null: false
    t.bigint "chapter_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chapter_id"], name: "index_reading_progresses_on_chapter_id"
    t.index ["fiction_id"], name: "index_reading_progresses_on_fiction_id"
    t.index ["status"], name: "index_reading_progresses_on_status"
    t.index ["user_id"], name: "index_reading_progresses_on_user_id"
  end

  create_table "scanlator_users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "scanlator_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scanlator_id"], name: "index_scanlator_users_on_scanlator_id"
    t.index ["user_id"], name: "index_scanlator_users_on_user_id"
  end

  create_table "scanlators", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "slug", null: false
    t.string "telegram_id"
    t.string "bank_url"
    t.string "extra_url"
    t.string "title", null: false
    t.string "description"
    t.boolean "convertable", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tags", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name"
  end

  create_table "user_pokemons", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "pokemon_id"
    t.bigint "user_id"
    t.integer "current_level", default: 0
    t.integer "battle_experience", default: 0
    t.string "character"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pokemon_id"], name: "index_user_pokemons_on_pokemon_id"
    t.index ["user_id"], name: "index_user_pokemons_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.boolean "admin", default: false
    t.bigint "avatar_id"
    t.integer "battle_win_rate", default: 50
    t.bigint "latest_read_comment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "pokemon_last_catch", default: "2023-09-18 02:18:35"
    t.datetime "pokemon_last_training", default: "2023-11-02 02:58:41"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.index ["avatar_id"], name: "index_users_on_avatar_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["latest_read_comment_id"], name: "index_users_on_latest_read_comment_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "youtube_channels", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "channel_id", null: false
    t.string "title", null: false
    t.string "thumbnail", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "youtube_videos", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "slug", null: false
    t.bigint "youtube_channel_id", null: false
    t.string "video_id", null: false
    t.string "title", null: false
    t.string "thumbnail", null: false
    t.string "tags"
    t.integer "comments_count", default: 0
    t.integer "views", default: 0
    t.datetime "published_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["youtube_channel_id"], name: "index_youtube_videos_on_youtube_channel_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bookshelf_fictions", "bookshelves"
  add_foreign_key "bookshelf_fictions", "fictions"
  add_foreign_key "bookshelves", "users"
  add_foreign_key "chapter_scanlators", "chapters"
  add_foreign_key "chapter_scanlators", "scanlators"
  add_foreign_key "chapters", "fictions", on_delete: :cascade
  add_foreign_key "chapters", "users", on_delete: :cascade
  add_foreign_key "chat_messages", "users"
  add_foreign_key "comments", "comments", column: "parent_id", on_delete: :cascade
  add_foreign_key "comments", "users", on_delete: :cascade
  add_foreign_key "fiction_genres", "fictions"
  add_foreign_key "fiction_genres", "genres"
  add_foreign_key "fiction_ratings", "fictions"
  add_foreign_key "fiction_ratings", "users"
  add_foreign_key "fiction_scanlators", "fictions"
  add_foreign_key "fiction_scanlators", "scanlators"
  add_foreign_key "pokemon_battle_logs", "users", column: "attacker_id"
  add_foreign_key "pokemon_battle_logs", "users", column: "defender_id"
  add_foreign_key "pokemon_battle_logs", "users", column: "winner_id"
  add_foreign_key "pokemon_type_relations", "pokemon_types"
  add_foreign_key "pokemon_type_relations", "pokemons"
  add_foreign_key "pokemons", "pokemons", column: "ancestor_id"
  add_foreign_key "pokemons", "pokemons", column: "descendant_id"
  add_foreign_key "publication_tags", "publications"
  add_foreign_key "publication_tags", "tags"
  add_foreign_key "publications", "users", on_delete: :cascade
  add_foreign_key "reading_progresses", "chapters", on_delete: :cascade
  add_foreign_key "reading_progresses", "fictions", on_delete: :cascade
  add_foreign_key "reading_progresses", "users", on_delete: :cascade
  add_foreign_key "scanlator_users", "scanlators"
  add_foreign_key "scanlator_users", "users"
  add_foreign_key "user_pokemons", "pokemons"
  add_foreign_key "user_pokemons", "users"
  add_foreign_key "users", "avatars"
  add_foreign_key "users", "comments", column: "latest_read_comment_id"
  add_foreign_key "youtube_videos", "youtube_channels"
end
