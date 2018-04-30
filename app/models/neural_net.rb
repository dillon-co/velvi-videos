class NeuralNet < ApplicationRecord

  has_many :nodes

  def forward_prop
    nodes.where(layer_number: 2).each do |middle_node| #for each node in the second layer multiply the first layer inputs by their respective weights
      second_node_matrix = []
      nodes.where(layer_number: 1).each do |input_node|
        weight = input_node.weights.find_by('weight.output_node = ?', middle_node).references(:weights)
        input_times_weight = input_node.input_num*weight
        second_node_matrix<<final_num = Math.sigmoid(input_times_weight)
      end
      middle_node.update(input_num: input_second_node_matrix.inject(:+))
    end
  end

  def back_prop

  end
end
