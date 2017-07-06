class AddEventToVideos < ActiveRecord::Migration[5.0]
  def change
    add_reference :videos, :event, foreign_key: true
  end
end
