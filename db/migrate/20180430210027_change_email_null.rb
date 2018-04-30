class ChangeEmailNull < ActiveRecord::Migration[5.0]
  def change
    change_column_null :raffle_emails, :email, false
    change_column_null :raffle_emails, :name, false
  end
end
