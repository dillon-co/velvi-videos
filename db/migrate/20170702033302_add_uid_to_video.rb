class AddUidToVideo < ActiveRecord::Migration[5.0]
  def change
    add_column :videos, :uid, :string
    add_column :videos, :description, :text
  end
end
