class AddEventNickNameToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :event_nick_name, :string
  end
end
