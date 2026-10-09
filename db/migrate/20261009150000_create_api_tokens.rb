# frozen_string_literal: true

# Personal access tokens for the chapter API. Only the SHA-256 digest is stored.
class CreateApiTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :api_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :token_digest, null: false
      t.string :token_prefix, null: false, limit: 8
      t.json :scopes, null: false
      t.datetime :last_used_at
      t.string :last_used_ip, limit: 45
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.timestamps
    end

    add_index :api_tokens, :token_digest, unique: true
  end
end
