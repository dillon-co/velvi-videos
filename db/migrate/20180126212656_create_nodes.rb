class CreateNodes < ActiveRecord::Migration[5.0]
  def change
    create_table :nodes do |t|
      t.belongs_to :neural_net

      t.string :name

      t.integer :node_type

      t.integer :layer_number
      t.integer :node_input
      t.integer :cell_state


      t.timestamps
    end
  end
end
