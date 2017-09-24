class AddNumFollowersToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :num_followers, :integer
  end
end
