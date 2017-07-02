class AddYoutubeFieldsToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :youtube_uid, :string
    add_column :users, :youtube_token, :string
    add_column :users, :youtube_name, :string
  end
end
