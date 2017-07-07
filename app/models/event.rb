# == Schema Information
#
# Table name: events
#
#  id          :integer          not null, primary key
#  title       :string
#  nick_name   :string
#  event_date  :datetime
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Event < ApplicationRecord
  belongs_to :user
  has_many :videos

  def create_event_video
    users_at_event = User.where(event_nick_name: nick_name)
    event_videos = get_event_videos_from_users(users_at_event)
    save_and_resize_videos(event_videos)
    add_all_videos_together
    add_music_and_watermark_to_movie
  end

  def create_and_save_event_video
    create_event_video
    save_event_video
  end

  def save_event_video
  end

  def get_event_videos_from_users(users_at_event)
    
  end

  def save_and_resize_videos(vids)
  end

  def add_all_videos_together
  end

  def add_music_and_watermark_to_movie
    add_music_to_movie
    add_watermark_to_movie
  end

  def add_music_to_movie
  end

  def add_watermark_to_movie
  end
end
