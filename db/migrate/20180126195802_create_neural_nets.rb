class CreateNeuralNets < ActiveRecord::Migration[5.0]
  def change
    create_table :neural_nets do |t|
      t.string :title
      t.string :description
      t.integer :neural_net_type

      t.integer :number_of_layers
      t.integer :number_of_inputs
      t.integer :number_of_outputs

      t.timestamps
    end
  end
end
