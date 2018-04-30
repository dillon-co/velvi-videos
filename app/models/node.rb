class Node < ApplicationRecord
  has_many :weights

  def multiply_weights
  end

  def lstm_cell(inputs)
  end

  def forget_gate(input) #what dowe keep, and what do we get rid of
  end

end
