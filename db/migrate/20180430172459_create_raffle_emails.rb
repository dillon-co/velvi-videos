class CreateRaffleEmails < ActiveRecord::Migration[5.0]
  def change
    create_table :raffle_emails do |t|
      t.string :email
      t.string :name
      t.integer :raffle_count

      t.timestamps
    end
  end
end
