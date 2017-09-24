# == Schema Information
#
# Table name: videos
#
#  id                  :integer          not null, primary key
#  user_id             :integer
#  title               :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  music_url           :string
#  non_music_url       :string
#  done_editing        :boolean          default(FALSE), not null
#  video_type          :integer
#  uid                 :string
#  description         :text
#  event_id            :integer
#  no_instagram_videos :boolean          default(FALSE)
#

require 'test_helper'

class VideoTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
