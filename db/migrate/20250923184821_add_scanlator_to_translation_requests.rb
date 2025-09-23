class AddScanlatorToTranslationRequests < ActiveRecord::Migration[8.0]
  def change
    add_reference :translation_requests, :scanlator, null: true, foreign_key: true, after: :user_id
  end
end
