# == Schema Information
#
# Table name: videos
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  title         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  music_url     :string
#  non_music_url :string
#  done_editing  :boolean          default(FALSE), not null
#  video_type    :integer
#  uid           :string
#  description   :text
#  event_id      :integer
#

class Video < ApplicationRecord
  belongs_to :user

  enum video_type: [:free, :paid]

  before_create :create_description


  def create_description
    self.description = "Here's this month's instagram compilation!\n\n\n\nIt was automatically made with the video editing A.I. at www.velvi.io."
  end

  def upload_to_youtube(vid_type='music')
    titty = "Instagram Compilation #{self.created_at.strftime("%B, %Y")}"
    temp_params = { title: titty, description: self.description, category: 'Sports',
                  keywords: ['parkour', 'freerunning', 'instagram', 'extreme sports'] }
                  #TODO Save tags as part of video and use those here

    refresh_token = self.user.youtube_refresh_token
    access_tokn = self.user.youtube_token
    Yt.configuration.client_id = ENV['VELVI_YOUTUBE_CLIENT_ID']
    Yt.configuration.client_secret = ENV["VELVI_VIDEO_INSTA_SECRET"]
    account = Yt::Account.new(access_token: access_tokn)
    vid_type == 'music' ? vid = self.music_url : vid = self.non_music_url
    puts "\n\n=====\n\n\nACCOUNT::::::>>>>>>>#{account.access_token}<<<<<<<<<<:::::::\n\n\n==============\n\n\n\n"
    account.upload_video vid, temp_params
  end
end
