class ReplaceDeviseWithCustomAuth < ActiveRecord::Migration[8.0]
  def change
    # Always ensure the users table exists
    unless table_exists?(:users)
      create_table :users do |t|
        t.string :email, null: false
        t.string :encrypted_password, null: false
        t.string :username
        t.datetime :created_at, null: false
        t.datetime :updated_at, null: false
        t.index [:email], unique: true
      end
    end

    # Always remove Devise columns (if they exist)
    remove_column :users, :reset_password_token, :string if column_exists?(:users, :reset_password_token)
    remove_column :users, :reset_password_sent_at, :datetime if column_exists?(:users, :reset_password_sent_at)
    remove_column :users, :remember_created_at, :datetime if column_exists?(:users, :remember_created_at)
    remove_column :users, :confirmation_token, :string if column_exists?(:users, :confirmation_token)
    remove_column :users, :confirmed_at, :datetime if column_exists?(:users, :confirmed_at)
    remove_column :users, :confirmation_sent_at, :datetime if column_exists?(:users, :confirmation_sent_at)
    remove_column :users, :unconfirmed_email, :string if column_exists?(:users, :unconfirmed_email)

    # Always add custom authentication fields (if they don't exist)
    add_column :users, :remember_token, :string unless column_exists?(:users, :remember_token)
    add_column :users, :email_verification_token, :string unless column_exists?(:users, :email_verification_token)
    add_column :users, :email_verified_at, :datetime unless column_exists?(:users, :email_verified_at)
    add_column :users, :email_verification_sent_at, :datetime unless column_exists?(:users, :email_verification_sent_at)
    add_column :users, :password_reset_token, :string unless column_exists?(:users, :password_reset_token)
    add_column :users, :password_reset_sent_at, :datetime unless column_exists?(:users, :password_reset_sent_at)

    # Always add indexes for the new fields (if they don't exist)
    add_index :users, :email_verification_token, unique: true unless index_exists?(:users, :email_verification_token)
    add_index :users, :password_reset_token, unique: true unless index_exists?(:users, :password_reset_token)
    add_index :users, :remember_token, unique: true unless index_exists?(:users, :remember_token)
  end
end
