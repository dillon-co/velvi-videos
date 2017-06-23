class AddFieldToVideo < ActiveRecord::Migration[5.0]
  def change
    add_column :videos, :done_editing, :boolean, default: false, null: false
  end
end
