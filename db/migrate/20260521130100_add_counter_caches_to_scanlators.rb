# frozen_string_literal: true

class AddCounterCachesToScanlators < ActiveRecord::Migration[8.0]
  def up
    add_column :scanlators, :fictions_count, :integer, default: 0, null: false, after: :convertable
    add_column :scanlators, :members_count, :integer, default: 0, null: false, after: :fictions_count

    say_with_time 'Backfilling scanlator counter caches' do
      Scanlator.unscoped.find_each do |scanlator|
        scanlator.update_columns(
          fictions_count: FictionScanlator.where(scanlator_id: scanlator.id).count,
          members_count: ScanlatorUser.where(scanlator_id: scanlator.id).count
        )
      end
    end
  end

  def down
    remove_column :scanlators, :fictions_count
    remove_column :scanlators, :members_count
  end
end
