class RevertBuiltInAuthenticator < ActiveRecord::Migration[8.0]
  def up
    # Drop the sessions table
    drop_table :sessions if table_exists?(:sessions)

    # Rename columns FROM custom auth TO built-in authenticator
    rename_column :users, :password_digest, :encrypted_password if column_exists?(:users, :password_digest)
    rename_column :users, :email_verification_token, :confirmation_token if column_exists?(:users, :email_verification_token)
    rename_column :users, :email_verified_at, :confirmed_at if column_exists?(:users, :email_verified_at)
    rename_column :users, :email_verification_sent_at, :confirmation_sent_at if column_exists?(:users, :email_verification_sent_at)
    rename_column :users, :password_reset_token, :reset_password_token if column_exists?(:users, :password_reset_token)
    rename_column :users, :password_reset_sent_at, :reset_password_sent_at if column_exists?(:users, :password_reset_sent_at)

    # Drop remember_token column
    remove_column :users, :remember_token if column_exists?(:users, :remember_token)

    # Remove custom authentication indexes
    remove_index :users, :email_verification_token if index_exists?(:users, :email_verification_token)
    remove_index :users, :password_reset_token if index_exists?(:users, :password_reset_token)
    remove_index :users, :remember_token if index_exists?(:users, :remember_token)

    # Remove existing built-in authenticator indexes if they exist to avoid conflicts
    # Use MySQL-compatible approach: try to remove, ignore if they don't exist
    begin
      remove_index :users, name: "index_users_on_confirmation_token"
    rescue ActiveRecord::StatementInvalid
      # Index doesn't exist, ignore the error
    end
    
    begin
      remove_index :users, name: "index_users_on_reset_password_token"
    rescue ActiveRecord::StatementInvalid
      # Index doesn't exist, ignore the error
    end

    # Add built-in authenticator indexes
    add_index :users, :confirmation_token, unique: true if column_exists?(:users, :confirmation_token)
    add_index :users, :reset_password_token, unique: true if column_exists?(:users, :reset_password_token)
  end

  def down
    # This migration converts TO built-in authenticator, so down method reverts TO custom auth
    # Add sessions table back
    create_table :sessions do |t|
      t.string :session_id, null: false
      t.text :data
      t.timestamps
    end

    add_index :sessions, :session_id, unique: true
    add_index :sessions, :updated_at

    # Rename columns back TO custom authentication names
    rename_column :users, :encrypted_password, :password_digest if column_exists?(:users, :encrypted_password)
    rename_column :users, :confirmation_token, :email_verification_token if column_exists?(:users, :confirmation_token)
    rename_column :users, :confirmed_at, :email_verified_at if column_exists?(:users, :confirmed_at)
    rename_column :users, :confirmation_sent_at, :email_verification_sent_at if column_exists?(:users, :confirmation_sent_at)
    rename_column :users, :reset_password_token, :password_reset_token if column_exists?(:users, :reset_password_token)
    rename_column :users, :reset_password_sent_at, :password_reset_sent_at if column_exists?(:users, :reset_password_sent_at)

    # Add custom auth columns back
    add_column :users, :remember_token, :string unless column_exists?(:users, :remember_token)

    # Remove built-in authenticator indexes
    remove_index :users, :confirmation_token if index_exists?(:users, :confirmation_token)
    remove_index :users, :reset_password_token if index_exists?(:users, :reset_password_token)

    # Add custom authentication indexes back
    add_index :users, :email_verification_token, unique: true if column_exists?(:users, :email_verification_token)
    add_index :users, :password_reset_token, unique: true if column_exists?(:users, :password_reset_token)
    add_index :users, :remember_token, unique: true if column_exists?(:users, :remember_token)
  end
end
