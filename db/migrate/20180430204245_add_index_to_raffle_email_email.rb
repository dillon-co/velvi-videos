class AddIndexToRaffleEmailEmail < ActiveRecord::Migration[5.0]
  def change
    add_index :raffle_emails, :email, unique: true
  end
end
