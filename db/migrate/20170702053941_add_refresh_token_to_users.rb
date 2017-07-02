class AddRefreshTokenToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :youtube_refresh_token, :string
  end
end
