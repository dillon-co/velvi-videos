class AddErrorToVideo < ActiveRecord::Migration[5.0]
  def change
    add_column :videos, :no_instagram_videos, :boolean, default: false
  end
end
