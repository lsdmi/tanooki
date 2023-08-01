class RemoveCaptionFromAds < ActiveRecord::Migration[7.0]
  def change
    remove_column :advertisements, :caption
  end
end
