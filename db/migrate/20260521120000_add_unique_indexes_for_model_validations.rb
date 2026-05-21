# frozen_string_literal: true

class AddUniqueIndexesForModelValidations < ActiveRecord::Migration[8.0]
  def up
    replace_index :genres, :name, unique: true
    replace_index :tags, :name, unique: true
    replace_index :pokemons, :name, unique: true

    deduplicate_user_names
    replace_index :users, :name, unique: true

    replace_index :reading_progresses, %i[user_id fiction_id], unique: true
  end

  def down
    remove_index :reading_progresses, column: %i[user_id fiction_id]
    remove_index :users, :name
    replace_index :pokemons, :name, unique: false
    replace_index :tags, :name, unique: false
    replace_index :genres, :name, unique: false
  end

  private

  def replace_index(table, column, unique:)
    remove_index table, column if index_exists?(table, column)
    add_index table, column, unique: unique
  end

  def deduplicate_user_names
    User.unscoped.group(:name).having('COUNT(*) > 1').pluck(:name).each do |name|
      User.unscoped.where(name: name).order(:id).offset(1).find_each.with_index(2) do |user, index|
        user.update_column(:name, "#{name} #{index}")
      end
    end
  end
end
