class AddUrlsToScanlators < ActiveRecord::Migration[7.2]
  def change
    add_column :scanlators, :bank_url, :string, after: :telegram_id
    add_column :scanlators, :extra_url, :string, after: :bank_url
  end
end
