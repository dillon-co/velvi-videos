class AddMoneyToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :money_in_account, :float, default: 0
  end
end
