class AddS3UrlsToVideos < ActiveRecord::Migration[5.0]
  def change
    add_column :videos, :music_url, :string
    add_column :videos, :non_music_url, :string
  end
end
