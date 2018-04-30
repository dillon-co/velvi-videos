class ChangeRaffleEmailDefaults < ActiveRecord::Migration[5.0]
  def change
    change_column_default :raffle_emails, :email, nil
    change_column_default :raffle_emails, :name, nil
  end
end
