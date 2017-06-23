class AddTypeToVideo < ActiveRecord::Migration[5.0]
  def change
    add_column :videos, :video_type, :integer
  end
end
